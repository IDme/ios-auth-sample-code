import Foundation

/// Public model representing the authenticated user's tokens.
public struct Credentials: Codable, Sendable, Equatable {
    /// The OAuth access token.
    public let accessToken: String

    /// The OAuth refresh token (if provided).
    public let refreshToken: String?

    /// The OIDC ID token (if OIDC mode was used).
    public let idToken: String?

    /// The token type (typically "Bearer").
    public let tokenType: String

    /// The date when the access token expires.
    public let expiresAt: Date

    /// Whether the access token has expired.
    public var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Whether the access token will expire within the given number of seconds.
    public func expiresWithin(seconds: TimeInterval) -> Bool {
        Date().addingTimeInterval(seconds) >= expiresAt
    }

    public init(
        accessToken: String,
        refreshToken: String?,
        idToken: String?,
        tokenType: String,
        expiresAt: Date
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
    }
}
