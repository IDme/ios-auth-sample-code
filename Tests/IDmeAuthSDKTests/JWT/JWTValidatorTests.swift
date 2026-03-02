import Testing
import Foundation
@testable import IDmeAuthSDK

final class MockJWKSFetcher: JWKSFetching, @unchecked Sendable {
    var jwks: JWKS?
    var error: Error?

    func fetchJWKS() async throws -> JWKS {
        if let error { throw error }
        return jwks!
    }
}

@Suite("JWTValidator")
struct JWTValidatorTests {
    @Test("Rejects non-RS256 algorithm")
    func rejectsNonRS256() async {
        let mockFetcher = MockJWKSFetcher()
        mockFetcher.jwks = JWKS(keys: [])

        let validator = JWTValidator(
            jwksFetcher: mockFetcher,
            issuer: "https://api.id.me",
            clientId: "test-client"
        )

        let header = Base64URL.encode("""
        {"alg":"HS256","typ":"JWT"}
        """.data(using: .utf8)!)
        let payload = Base64URL.encode("""
        {"sub":"user-123"}
        """.data(using: .utf8)!)
        let signature = Base64URL.encode(Data([0x01]))
        let jwt = "\(header).\(payload).\(signature)"

        await #expect(throws: IDmeAuthError.self) {
            try await validator.validate(idToken: jwt, nonce: nil)
        }
    }

    @Test("Rejects when kid not found in JWKS")
    func rejectsKeyNotFound() async {
        let mockFetcher = MockJWKSFetcher()
        mockFetcher.jwks = JWKS(keys: [
            JWK(kty: "RSA", kid: "other-kid", use: "sig", alg: "RS256", n: "abc", e: "AQAB")
        ])

        let validator = JWTValidator(
            jwksFetcher: mockFetcher,
            issuer: "https://api.id.me",
            clientId: "test-client"
        )

        let header = Base64URL.encode("""
        {"alg":"RS256","kid":"missing-kid","typ":"JWT"}
        """.data(using: .utf8)!)
        let payload = Base64URL.encode("""
        {"sub":"user-123"}
        """.data(using: .utf8)!)
        let signature = Base64URL.encode(Data([0x01]))
        let jwt = "\(header).\(payload).\(signature)"

        await #expect(throws: IDmeAuthError.self) {
            try await validator.validate(idToken: jwt, nonce: nil)
        }
    }
}
