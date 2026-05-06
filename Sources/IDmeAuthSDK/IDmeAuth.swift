import AuthenticationServices
import Foundation

/// Main entry point for the IDmeAuthSDK.
///
/// Provides login, logout, token management, and user attribute retrieval
/// using OAuth 2.0 with PKCE.
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

    /// Creates a new IDmeAuth instance with the given configuration.
    public convenience init(configuration: IDmeConfiguration) {
        let httpClient = URLSessionHTTPClient()
        let credentialStore = CredentialStore()
        let refresher = TokenRefresher(configuration: configuration, httpClient: httpClient)
        let tokenManager = TokenManager(credentialStore: credentialStore, refresher: refresher)
        self.init(configuration: configuration, tokenManager: tokenManager, httpClient: httpClient)
    }

    /// Internal initializer for dependency injection in tests.
    init(
        configuration: IDmeConfiguration,
        tokenManager: TokenManager,
        httpClient: HTTPClient
    ) {
        self.configuration = configuration
        self.tokenManager = tokenManager
        self.httpClient = httpClient
    }

    // MARK: - Login

    /// Starts the authentication flow using a system browser sheet.
    ///
    /// - Parameter anchor: The window to present the authentication sheet from.
    /// - Returns: The authenticated user's credentials.
    @discardableResult
    public func login(from anchor: PresentationAnchor) async throws -> Credentials {
        let webSession = WebAuthSession(anchor: anchor)
        return try await login(webSession: webSession)
    }

    /// Internal login with injectable web session for testing.
    func login(webSession: WebAuthSessionProtocol) async throws -> Credentials {
        let authURL: URL
        let state: String
        let codeVerifier: String

        switch configuration.verificationType {
        case .single:
            let request = try AuthorizationRequest(configuration: configuration)
            authURL = request.url
            state = request.state
            codeVerifier = request.pkce.codeVerifier

        case .groups:
            let request = try GroupsRequest(configuration: configuration)
            authURL = request.url
            state = request.state
            codeVerifier = request.pkce.codeVerifier
        }

        Log.info("Starting auth session: \(configuration.verificationType.rawValue) mode")

        let callbackURL = try await webSession.authenticate(
            url: authURL,
            callbackScheme: configuration.redirectScheme
        )

        let code = try extractAuthorizationCode(from: callbackURL, expectedState: state)

        let tokenExchange = TokenExchangeRequest(configuration: configuration, httpClient: httpClient)
        let tokenResponse = try await tokenExchange.exchange(code: code, codeVerifier: codeVerifier)

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
    /// Uses the client credentials (client_id) to authenticate.
    /// The policy `handle` can be used as the OAuth `scope` parameter.
    ///
    /// - Returns: An array of available policies.
    public func policies() async throws -> [Policy] {
        let url = APIEndpoint.policies(environment: configuration.environment)

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
        ]
        if let clientSecret = configuration.clientSecret {
            queryItems.append(URLQueryItem(name: "client_secret", value: clientSecret))
        }
        components.queryItems = queryItems

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

    // MARK: - Attributes

    /// Fetches the authenticated user's attributes from the OAuth attributes endpoint.
    ///
    /// - Returns: The user's attributes and verification statuses.
    public func attributes() async throws -> AttributeResponse {
        let creds = try await tokenManager.validCredentials(minTTL: 60)
        let url = APIEndpoint.attributes(environment: configuration.environment)

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
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

    // MARK: - Raw Payload

    /// Fetches the raw payload from the attributes endpoint as key-value pairs.
    ///
    /// The endpoint returns a JWT; this method decodes it and returns all claims
    /// as string key-value pairs, preserving the full payload.
    ///
    /// - Returns: An array of (key, value) pairs from the JWT payload.
    public func rawPayload() async throws -> [(key: String, value: String)] {
        let creds = try await tokenManager.validCredentials(minTTL: 60)
        let url = APIEndpoint.attributes(environment: configuration.environment)

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
