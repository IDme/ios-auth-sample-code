import Foundation

/// The authentication mode to use.
public enum IDmeAuthMode: String, Sendable {
    /// Standard OAuth 2.0 Authorization Code flow. Requires `clientSecret`.
    case oauth

    /// OAuth 2.0 with PKCE (recommended for mobile apps). No client secret needed.
    case oauthPKCE

    /// OpenID Connect flow. Adds ID token validation with nonce.
    case oidc
}
