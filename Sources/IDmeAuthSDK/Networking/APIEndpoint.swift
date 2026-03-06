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

    /// Attributes endpoint (OAuth).
    static func attributes(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("api/public/v3/attributes.json")
    }

    /// Policies endpoint.
    static func policies(environment: IDmeEnvironment) -> URL {
        environment.apiBaseURL.appendingPathComponent("api/public/v3/policies")
    }
}
