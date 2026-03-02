import Foundation

/// Configuration for the IDmeAuth client.
public struct IDmeConfiguration: Sendable {
    /// The OAuth client ID issued by ID.me.
    public let clientId: String

    /// The redirect URI registered with ID.me (e.g., "yourapp://idme/callback").
    public let redirectURI: String

    /// The OAuth scopes to request.
    public let scopes: [IDmeScope]

    /// The environment to use (sandbox or production).
    public let environment: IDmeEnvironment

    /// The authentication mode (OAuth, OAuth+PKCE, or OIDC).
    public let authMode: IDmeAuthMode

    /// The verification type (single scope or groups/multi-scope).
    public let verificationType: IDmeVerificationType

    /// The client secret. Required for `.oauth` mode; unused for `.oauthPKCE`.
    public let clientSecret: String?

    public init(
        clientId: String,
        redirectURI: String,
        scopes: [IDmeScope],
        environment: IDmeEnvironment = .production,
        authMode: IDmeAuthMode = .oauthPKCE,
        verificationType: IDmeVerificationType = .single,
        clientSecret: String? = nil
    ) {
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.environment = environment
        self.authMode = authMode
        self.verificationType = verificationType
        self.clientSecret = clientSecret
    }

    /// The redirect URI scheme extracted from the URI string.
    var redirectScheme: String? {
        URL(string: redirectURI)?.scheme
    }
}
