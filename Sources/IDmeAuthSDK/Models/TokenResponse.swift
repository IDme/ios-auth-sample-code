import Foundation

/// Internal model representing the JSON response from `/oauth/token`.
struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let idToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case scope
    }

    /// Converts to the public `Credentials` type.
    func toCredentials() -> Credentials {
        Credentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            tokenType: tokenType,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}
