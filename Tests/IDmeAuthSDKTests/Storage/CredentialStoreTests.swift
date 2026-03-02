import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("CredentialStore")
struct CredentialStoreTests {
    @Test("Credentials round-trip through JSON serialization")
    func serialization() throws {
        let credentials = TestFixtures.makeCredentials(
            accessToken: "access-123",
            refreshToken: "refresh-456",
            idToken: "id-789"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(credentials)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Credentials.self, from: data)

        #expect(decoded.accessToken == "access-123")
        #expect(decoded.refreshToken == "refresh-456")
        #expect(decoded.idToken == "id-789")
        #expect(decoded.tokenType == "Bearer")
    }

    @Test("Handles nil optional fields")
    func nilOptionals() throws {
        let credentials = TestFixtures.makeCredentials(
            refreshToken: nil,
            idToken: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(credentials)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Credentials.self, from: data)

        #expect(decoded.refreshToken == nil)
        #expect(decoded.idToken == nil)
    }

    @Test("Mock store save and load")
    func mockSaveAndLoad() throws {
        let store = MockCredentialStore()
        let credentials = TestFixtures.makeCredentials()

        try store.save(credentials)
        let loaded = try store.load()

        #expect(loaded?.accessToken == credentials.accessToken)
        #expect(store.saveCallCount == 1)
    }

    @Test("Mock store delete")
    func mockDelete() throws {
        let store = MockCredentialStore()
        store.stored = TestFixtures.makeCredentials()

        try store.delete()

        #expect(try store.load() == nil)
        #expect(store.deleteCallCount == 1)
    }
}
