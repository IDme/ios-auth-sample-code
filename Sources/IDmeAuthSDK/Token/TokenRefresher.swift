import Foundation

/// Protocol for token refresh, enabling mock injection in tests.
protocol TokenRefreshing: Sendable {
    func refresh(refreshToken: String) async throws -> TokenResponse
}

/// Handles the refresh_token grant type.
struct TokenRefresher: TokenRefreshing {
    private let configuration: IDmeConfiguration
    private let httpClient: HTTPClient

    init(configuration: IDmeConfiguration, httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.configuration = configuration
        self.httpClient = httpClient
    }

    func refresh(refreshToken: String) async throws -> TokenResponse {
        let tokenURL = APIEndpoint.token(environment: configuration.environment)

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": configuration.clientId
        ]

        let bodyString = body.map { "\($0.key)=\(percentEncode($0.value))" }.joined(separator: "&")

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw IDmeAuthError.tokenRefreshFailed(statusCode: response.statusCode, message: message)
        }

        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }
    }

    private func percentEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
