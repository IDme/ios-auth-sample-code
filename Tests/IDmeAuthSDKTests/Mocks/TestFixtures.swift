import Foundation
@testable import IDmeAuthSDK

enum TestFixtures {
    static let clientId = "test-client-id"
    static let redirectURI = "testapp://idme/callback"
    static let clientSecret = "test-client-secret"

    static var singleConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military],
            environment: .production,
            authMode: .oauthPKCE,
            verificationType: .single
        )
    }

    static var groupsConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military, .firstResponder],
            environment: .production,
            authMode: .oauthPKCE,
            verificationType: .groups
        )
    }

    static var oauthConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military],
            environment: .production,
            authMode: .oauth,
            verificationType: .single,
            clientSecret: clientSecret
        )
    }

    static var oidcConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.openid, .profile, .email],
            environment: .production,
            authMode: .oidc,
            verificationType: .single
        )
    }

    static var sandboxConfig: IDmeConfiguration {
        IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: [.military],
            environment: .sandbox,
            authMode: .oauthPKCE,
            verificationType: .single
        )
    }

    static func makeCredentials(
        accessToken: String = "test-access-token",
        refreshToken: String? = "test-refresh-token",
        idToken: String? = nil,
        expiresIn: TimeInterval = 3600
    ) -> Credentials {
        Credentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
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

    static var userInfoJSON: Data {
        """
        {
            "sub": "user-123",
            "email": "test@example.com",
            "email_verified": true,
            "given_name": "John",
            "family_name": "Doe",
            "name": "John Doe"
        }
        """.data(using: .utf8)!
    }
}
