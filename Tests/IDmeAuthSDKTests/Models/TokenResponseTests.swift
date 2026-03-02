import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("TokenResponse")
struct TokenResponseTests {
    @Test("Decodes standard token response")
    func decodeStandard() throws {
        let json = TestFixtures.tokenResponseJSON
        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        #expect(response.accessToken == "new-access-token")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == 3600)
        #expect(response.refreshToken == "new-refresh-token")
        #expect(response.scope == "military")
    }

    @Test("Decodes response with ID token")
    func decodeWithIdToken() throws {
        let json = """
        {
            "access_token": "at",
            "token_type": "Bearer",
            "expires_in": 1800,
            "refresh_token": "rt",
            "id_token": "eyJhbGciOiJSUzI1NiJ9.payload.sig",
            "scope": "openid profile"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)
        #expect(response.idToken == "eyJhbGciOiJSUzI1NiJ9.payload.sig")
    }

    @Test("Converts to Credentials")
    func toCredentials() throws {
        let json = TestFixtures.tokenResponseJSON
        let response = try JSONDecoder().decode(TokenResponse.self, from: json)
        let credentials = response.toCredentials()

        #expect(credentials.accessToken == "new-access-token")
        #expect(credentials.refreshToken == "new-refresh-token")
        #expect(credentials.tokenType == "Bearer")
        #expect(!credentials.isExpired)
    }

    @Test("Decodes minimal response without optional fields")
    func decodeMinimal() throws {
        let json = """
        {
            "access_token": "at",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)
        #expect(response.accessToken == "at")
        #expect(response.refreshToken == nil)
        #expect(response.idToken == nil)
        #expect(response.scope == nil)
    }
}
