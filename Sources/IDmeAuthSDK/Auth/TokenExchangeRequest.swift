import Foundation

/// Handles the OAuth token exchange (authorization code → tokens).
struct TokenExchangeRequest {
    private let httpClient: HTTPClient
    private let configuration: IDmeConfiguration

    init(configuration: IDmeConfiguration, httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.configuration = configuration
        self.httpClient = httpClient
    }

    /// Exchanges an authorization code for tokens.
    func exchange(code: String, codeVerifier: String?) async throws -> TokenResponse {
        let tokenURL = APIEndpoint.token(environment: configuration.environment)

        var body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": configuration.redirectURI,
            "client_id": configuration.clientId
        ]

        if let codeVerifier {
            body["code_verifier"] = codeVerifier
        }

        if let clientSecret = configuration.clientSecret {
            body["client_secret"] = clientSecret
        }

        let bodyString = body.map { "\($0.key)=\(percentEncode($0.value))" }.joined(separator: "&")

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await performRequest(request)

        guard (200...299).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw IDmeAuthError.tokenExchangeFailed(statusCode: response.statusCode, message: message)
        }

        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }
    }

    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
