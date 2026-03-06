import Foundation
@testable import IDmeAuthSDK

enum TestFixtures {
    static let clientId = "test-client-id"
    static let redirectURI = "testapp://idme/callback"

    static var singleConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military],
            environment: .production,
            verificationType: .single
        )
    }

    static var groupsConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military, .firstResponder],
            environment: .production,
            verificationType: .groups
        )
    }

    static var sandboxConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military],
            environment: .sandbox,
            verificationType: .single
        )
    }

    static func makeCredentials(
        accessToken: String = "test-access-token",
        refreshToken: String? = "test-refresh-token",
        expiresIn: TimeInterval = 3600
    ) -> Credentials {
        Credentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }

    static var tokenResponseJSON: Data {
        """
        {
            "access_token": "new-access-token",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "new-refresh-token",
            "scope": "military"
        }
        """.data(using: .utf8)!
    }

    static var attributesJSON: Data {
        """
        {
            "attributes": [
                {"handle": "uuid", "name": "UUID", "value": "user-123"},
                {"handle": "email", "name": "Email", "value": "test@example.com"}
            ],
            "status": [
                {"group": "military", "subgroups": ["Veteran"], "verified": true}
            ]
        }
        """.data(using: .utf8)!
    }
}
