import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("Credentials")
struct CredentialsTests {
    @Test("isExpired is true for past dates")
    func isExpired() {
        let expired = Credentials(
            accessToken: "token", refreshToken: nil, idToken: nil,
            tokenType: "Bearer", expiresAt: Date().addingTimeInterval(-60)
        )
        #expect(expired.isExpired)

        let valid = Credentials(
            accessToken: "token", refreshToken: nil, idToken: nil,
            tokenType: "Bearer", expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(!valid.isExpired)
    }

    @Test("expiresWithin checks TTL threshold")
    func expiresWithin() {
        let credentials = Credentials(
            accessToken: "token", refreshToken: nil, idToken: nil,
            tokenType: "Bearer", expiresAt: Date().addingTimeInterval(30)
        )

        #expect(credentials.expiresWithin(seconds: 60))
        #expect(!credentials.expiresWithin(seconds: 10))
    }

    @Test("Equatable conformance")
    func equatable() {
        let date = Date()
        let a = Credentials(
            accessToken: "token", refreshToken: "refresh", idToken: nil,
            tokenType: "Bearer", expiresAt: date
        )
        let b = Credentials(
            accessToken: "token", refreshToken: "refresh", idToken: nil,
            tokenType: "Bearer", expiresAt: date
        )
        #expect(a == b)
    }
}
