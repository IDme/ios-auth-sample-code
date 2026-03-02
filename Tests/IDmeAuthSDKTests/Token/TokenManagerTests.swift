import Testing
import Foundation
@testable import IDmeAuthSDK

final class MockTokenRefresher: TokenRefreshing, @unchecked Sendable {
    var result: TokenResponse?
    var error: Error?
    var refreshCallCount = 0

    func refresh(refreshToken: String) async throws -> TokenResponse {
        refreshCallCount += 1
        if let error { throw error }
        return result!
    }
}

@Suite("TokenManager")
struct TokenManagerTests {
    @Test("Store and retrieve credentials")
    func storeAndRetrieve() async throws {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        let creds = TestFixtures.makeCredentials()
        try await manager.store(creds)

        let retrieved = try await manager.currentCredentials()
        #expect(retrieved?.accessToken == creds.accessToken)
    }

    @Test("Returns non-expired token without refreshing")
    func validCredentialsNoRefresh() async throws {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        let creds = TestFixtures.makeCredentials(expiresIn: 3600)
        try await manager.store(creds)

        let valid = try await manager.validCredentials(minTTL: 60)
        #expect(valid.accessToken == creds.accessToken)
        #expect(refresher.refreshCallCount == 0)
    }

    @Test("Refreshes expiring token")
    func refreshesExpiring() async throws {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        refresher.result = TokenResponse(
            accessToken: "refreshed-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: "new-refresh",
            idToken: nil,
            scope: nil
        )
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        let creds = TestFixtures.makeCredentials(expiresIn: 30)
        try await manager.store(creds)

        let valid = try await manager.validCredentials(minTTL: 60)
        #expect(valid.accessToken == "refreshed-token")
        #expect(refresher.refreshCallCount == 1)
    }

    @Test("Throws notAuthenticated when no credentials")
    func throwsNotAuthenticated() async {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        await #expect(throws: IDmeAuthError.self) {
            try await manager.validCredentials()
        }
    }

    @Test("Throws when no refresh token available")
    func throwsNoRefreshToken() async throws {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        let creds = TestFixtures.makeCredentials(refreshToken: nil, expiresIn: 30)
        try await manager.store(creds)

        await #expect(throws: IDmeAuthError.self) {
            try await manager.validCredentials(minTTL: 60)
        }
    }

    @Test("Clear removes credentials")
    func clearCredentials() async throws {
        let store = MockCredentialStore()
        let refresher = MockTokenRefresher()
        let manager = TokenManager(credentialStore: store, refresher: refresher)

        let creds = TestFixtures.makeCredentials()
        try await manager.store(creds)
        try await manager.clear()

        let retrieved = try await manager.currentCredentials()
        #expect(retrieved == nil)
        #expect(store.deleteCallCount == 1)
    }
}
