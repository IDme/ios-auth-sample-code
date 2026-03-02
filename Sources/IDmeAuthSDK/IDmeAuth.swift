import AuthenticationServices
import Foundation

/// Main entry point for the IDmeAuthSDK.
///
/// Provides login, logout, token management, and user info retrieval.
///
/// ```swift
/// let idme = IDmeAuth(configuration: IDmeConfiguration(
///     clientId: "YOUR_CLIENT_ID",
///     redirectURI: "yourapp://idme/callback",
///     scopes: [.military],
///     verificationType: .single
/// ))
///
/// let credentials = try await idme.login(from: window)
/// ```
@MainActor
public final class IDmeAuth {
    private let configuration: IDmeConfiguration
    private let tokenManager: TokenManager
    private let httpClient: HTTPClient
    private let jwksFetcher: JWKSFetching
    private var lastNonce: String?

    /// Creates a new IDmeAuth instance with the given configuration.
    public convenience init(configuration: IDmeConfiguration) {
        let httpClient = URLSessionHTTPClient()
        let credentialStore = CredentialStore()
        let refresher = TokenRefresher(configuration: configuration, httpClient: httpClient)
        let tokenManager = TokenManager(credentialStore: credentialStore, refresher: refresher)
        let jwksFetcher = JWKSClient(environment: configuration.environment, httpClient: httpClient)
        self.init(configuration: configuration, tokenManager: tokenManager,
                  httpClient: httpClient, jwksFetcher: jwksFetcher)
    }

    /// Internal initializer for dependency injection in tests.
    init(
        configuration: IDmeConfiguration,
        tokenManager: TokenManager,
        httpClient: HTTPClient,
        jwksFetcher: JWKSFetching
    ) {
        self.configuration = configuration
        self.tokenManager = tokenManager
        self.httpClient = httpClient
        self.jwksFetcher = jwksFetcher
    }

    // MARK: - Login

    /// Starts the authentication flow using a system browser sheet.
    ///
    /// - Parameter anchor: The window to present the authentication sheet from.
    /// - Returns: The authenticated user's credentials.
    @discardableResult
    public func login(from anchor: PresentationAnchor) async throws -> Credentials {
        try validateConfiguration()

        let webSession = WebAuthSession(anchor: anchor)
        return try await login(webSession: webSession)
    }

    /// Internal login with injectable web session for testing.
    func login(webSession: WebAuthSessionProtocol) async throws -> Credentials {
        try validateConfiguration()

        let authURL: URL
        let state: String
        let nonce: String?
        let pkce: PKCEGenerator?

        switch configuration.verificationType {
        case .single:
            let request = try AuthorizationRequest(configuration: configuration)
            authURL = request.url
            state = request.state
            nonce = request.nonce
            pkce = request.pkce

        case .groups:
            let request = try GroupsRequest(configuration: configuration)
            authURL = request.url
            state = request.state
            nonce = request.nonce
            pkce = request.pkce
        }

        self.lastNonce = nonce

        Log.info("Starting auth session: \(configuration.verificationType.rawValue) mode")

        let callbackURL = try await webSession.authenticate(
            url: authURL,
            callbackScheme: configuration.redirectScheme
        )

        let code = try extractAuthorizationCode(from: callbackURL, expectedState: state)

        let tokenExchange = TokenExchangeRequest(configuration: configuration, httpClient: httpClient)
        let tokenResponse = try await tokenExchange.exchange(code: code, codeVerifier: pkce?.codeVerifier)

        // Validate ID token for OIDC mode
        if configuration.authMode == .oidc, let idToken = tokenResponse.idToken {
            let issuer = configuration.environment.apiBaseURL.appendingPathComponent("oidc").absoluteString
            let validator = JWTValidator(jwksFetcher: jwksFetcher, issuer: issuer, clientId: configuration.clientId)
            try await validator.validate(idToken: idToken, nonce: nonce)
        }

        let credentials = tokenResponse.toCredentials()
        try await tokenManager.store(credentials)

        Log.info("Login successful")
        return credentials
    }

    // MARK: - Credentials

    /// Returns valid credentials, automatically refreshing if they expire within `minTTL` seconds.
    ///
    /// - Parameter minTTL: Minimum time-to-live in seconds. Defaults to 60.
    /// - Returns: Valid credentials.
    public func credentials(minTTL: TimeInterval = 60) async throws -> Credentials {
        try await tokenManager.validCredentials(minTTL: minTTL)
    }

    // MARK: - Policies

    /// Fetches the available verification policies for the organization.
    ///
    /// Uses the client credentials (client_id and client_secret) to authenticate.
    /// The policy `handle` can be used as the OAuth `scope` parameter.
    ///
    /// - Returns: An array of available policies.
    public func policies() async throws -> [Policy] {
        let url = APIEndpoint.policies(environment: configuration.environment)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "client_secret", value: configuration.clientSecret),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            throw IDmeAuthError.unexpectedResponse(statusCode: response.statusCode)
        }

        do {
            return try JSONDecoder().decode([Policy].self, from: data)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }
    }

    // MARK: - User Info

    /// Fetches the authenticated user's profile information.
    ///
    /// - Returns: The user's profile info.
    public func userInfo() async throws -> UserInfo {
        let creds = try await tokenManager.validCredentials(minTTL: 60)
        let url = APIEndpoint.userInfo(environment: configuration.environment)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            throw IDmeAuthError.unexpectedResponse(statusCode: response.statusCode)
        }

        let jsonData = try Self.extractJSON(from: data)

        do {
            return try JSONDecoder().decode(UserInfo.self, from: jsonData)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }
    }

    // MARK: - Raw Payload

    /// Fetches the raw payload from the userinfo endpoint as key-value pairs.
    ///
    /// The endpoint returns a JWT; this method decodes it and returns all claims
    /// as string key-value pairs, preserving the full payload.
    ///
    /// - Returns: An array of (key, value) pairs from the JWT payload.
    public func rawPayload() async throws -> [(key: String, value: String)] {
        let creds = try await tokenManager.validCredentials(minTTL: 60)
        let url = APIEndpoint.userInfo(environment: configuration.environment)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            throw IDmeAuthError.unexpectedResponse(statusCode: response.statusCode)
        }

        let jsonData = try Self.extractJSON(from: data)

        guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw IDmeAuthError.decodingFailed(underlying: "Payload is not a JSON object")
        }

        return dict.sorted(by: { $0.key < $1.key }).map { key, value in
            (key: key, value: Self.stringValue(value))
        }
    }

    private static func stringValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let array as [Any]:
            let items = array.map { stringValue($0) }
            return items.joined(separator: ", ")
        case let dict as [String: Any]:
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "\(dict)"
        default:
            return "\(value)"
        }
    }

    // MARK: - Attributes (OAuth)

    /// Fetches the authenticated user's attributes (OAuth mode).
    ///
    /// Returns the ID.me attributes/status format used by OAuth and PKCE flows.
    /// For OIDC flows, use ``userInfo()`` instead.
    ///
    /// - Returns: The user's attributes and verification statuses.
    public func attributes() async throws -> AttributeResponse {
        let creds = try await tokenManager.validCredentials(minTTL: 60)
        let url = APIEndpoint.userInfo(environment: configuration.environment)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            throw IDmeAuthError.unexpectedResponse(statusCode: response.statusCode)
        }

        let jsonData = try Self.extractJSON(from: data)

        do {
            return try JSONDecoder().decode(AttributeResponse.self, from: jsonData)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }
    }

    // MARK: - Logout

    /// Clears all stored credentials and tokens.
    public func logout() {
        Task {
            try? await tokenManager.clear()
        }
        Log.info("User logged out")
    }

    // MARK: - Private

    /// Extracts JSON data from a response that may be plain JSON or a JWT.
    private static func extractJSON(from data: Data) throws -> Data {
        if let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
           raw.hasPrefix("eyJ") {
            let decoded = try JWTDecoder.decode(raw)
            return try JSONSerialization.data(withJSONObject: decoded.payload)
        }
        return data
    }

    private func validateConfiguration() throws {
        if configuration.authMode == .oauth && configuration.clientSecret == nil {
            throw IDmeAuthError.missingClientSecret
        }

        if configuration.verificationType == .groups && configuration.environment == .sandbox {
            throw IDmeAuthError.groupsNotAvailableInSandbox
        }

        guard URL(string: configuration.redirectURI) != nil else {
            throw IDmeAuthError.invalidRedirectURI
        }
    }

    private func extractAuthorizationCode(from url: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw IDmeAuthError.invalidCallbackURL
        }

        let queryItems = components.queryItems ?? []

        // Check for error response
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            if error == "access_denied" {
                throw IDmeAuthError.userCancelled
            }
            let description = queryItems.first(where: { $0.name == "error_description" })?.value ?? error
            throw IDmeAuthError.tokenExchangeFailed(statusCode: 0, message: description)
        }

        // Validate state
        if let returnedState = queryItems.first(where: { $0.name == "state" })?.value {
            guard returnedState == expectedState else {
                throw IDmeAuthError.stateMismatch
            }
        }

        // Extract code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw IDmeAuthError.missingAuthorizationCode
        }

        return code
    }
}
