import Foundation

/// Builds the authorization URL for single scope/policy flows.
struct AuthorizationRequest {
    let url: URL
    let state: String
    let pkce: PKCEGenerator

    /// Builds the `/oauth/authorize` URL with the appropriate query parameters.
    init(configuration: IDmeConfiguration) throws {
        guard URL(string: configuration.redirectURI) != nil else {
            throw IDmeAuthError.invalidRedirectURI
        }

        let state = StateGenerator.generate()
        self.state = state

        let pkceGen = PKCEGenerator()
        self.pkce = pkceGen

        let queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: IDmeScope.authorizeString(from: configuration.scopes)),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkceGen.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: pkceGen.codeChallengeMethod)
        ]

        var components = URLComponents(url: APIEndpoint.authorize(environment: configuration.environment),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw IDmeAuthError.invalidRedirectURI
        }
        self.url = url
    }
}
