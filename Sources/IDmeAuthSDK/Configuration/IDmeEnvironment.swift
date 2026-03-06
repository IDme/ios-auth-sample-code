import Foundation

/// The ID.me environment to connect to.
public enum IDmeEnvironment: String, Sendable {
    case sandbox
    case production

    /// Base URL for the API (authorize, token, attributes).
    var apiBaseURL: URL {
        switch self {
        case .sandbox:
            return URL(string: "https://api.idmelabs.com")!
        case .production:
            return URL(string: "https://api.id.me")!
        }
    }

    /// Base URL for the groups endpoint (production only).
    var groupsBaseURL: URL {
        URL(string: "https://groups.id.me")!
    }
}
