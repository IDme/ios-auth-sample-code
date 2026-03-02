import Foundation

/// Builds the groups.id.me URL for multiple scope/policy flows.
struct GroupsRequest {
    let url: URL
    let state: String
    let nonce: String?
    let pkce: PKCEGenerator?

    /// Builds the groups endpoint URL with the appropriate query parameters.
    /// - Throws: `IDmeAuthError.groupsNotAvailableInSandbox` if environment is sandbox.
    init(configuration: IDmeConfiguration) throws {
        guard configuration.environment == .production else {
            throw IDmeAuthError.groupsNotAvailableInSandbox
        }

        guard URL(string: configuration.redirectURI) != nil else {
            throw IDmeAuthError.invalidRedirectURI
        }

        let state = StateGenerator.generate()
        self.state = state

        var queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scopes", value: IDmeScope.groupsString(from: configuration.scopes)),
            URLQueryItem(name: "state", value: state)
        ]

        // PKCE parameters
        var pkceGen: PKCEGenerator?
        if configuration.authMode == .oauthPKCE || configuration.authMode == .oidc {
            let gen = PKCEGenerator()
            pkceGen = gen
            queryItems.append(URLQueryItem(name: "code_challenge", value: gen.codeChallenge))
            queryItems.append(URLQueryItem(name: "code_challenge_method", value: gen.codeChallengeMethod))
        }
        self.pkce = pkceGen

        // OIDC nonce
        var nonceValue: String?
        if configuration.authMode == .oidc {
            let nonce = NonceGenerator.generate()
            nonceValue = nonce
            queryItems.append(URLQueryItem(name: "nonce", value: nonce))
        }
        self.nonce = nonceValue

        var components = URLComponents(url: APIEndpoint.groups(environment: configuration.environment),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw IDmeAuthError.invalidRedirectURI
        }
        self.url = url
    }
}
