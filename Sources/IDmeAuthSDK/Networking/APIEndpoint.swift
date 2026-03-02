import Foundation

/// API endpoint paths for ID.me services.
enum APIEndpoint {
    /// OAuth authorization endpoint (single scope/policy).
    static func authorize(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("oauth/authorize")
    }

    /// Groups endpoint (multiple scopes/policies, production only).
    static func groups(environment: IDmeEnvironment) -> URL {
        environment.groupsBaseURL
    }

    /// OAuth token endpoint.
    static func token(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("oauth/token")
    }

    /// UserInfo endpoint.
    static func userInfo(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("api/public/v3/userinfo")
    }

    /// Policies endpoint.
    static func policies(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("api/public/v3/policies")
    }

    /// OIDC discovery endpoint.
    static func discovery(environment: IDmeEnvironment) -> URL {
        environment.discoveryURL
    }

    /// JWKS endpoint.
    static func jwks(environment: IDmeEnvironment) -> URL {
        environment.jwksURL
    }
}
