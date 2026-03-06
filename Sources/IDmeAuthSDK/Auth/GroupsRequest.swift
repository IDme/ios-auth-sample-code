import Foundation

/// Builds the groups.id.me URL for multiple scope/policy flows.
struct GroupsRequest {
    let url: URL
    let state: String
    let pkce: PKCEGenerator

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

        let pkceGen = PKCEGenerator()
        self.pkce = pkceGen

        let queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scopes", value: IDmeScope.groupsString(from: configuration.scopes)),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkceGen.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: pkceGen.codeChallengeMethod)
        ]

        var components = URLComponents(url: APIEndpoint.groups(environment: configuration.environment),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw IDmeAuthError.invalidRedirectURI
        }
        self.url = url
    }
}
