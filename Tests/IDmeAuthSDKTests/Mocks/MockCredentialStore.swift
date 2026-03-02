import Foundation
@testable import IDmeAuthSDK

final class MockCredentialStore: CredentialStoring, @unchecked Sendable {
    var stored: Credentials?
    var saveCallCount = 0
    var deleteCallCount = 0
    var shouldThrow = false

    func save(_ credentials: Credentials) throws {
        if shouldThrow { throw IDmeAuthError.keychainError(status: -1) }
        saveCallCount += 1
        stored = credentials
    }

    func load() throws -> Credentials? {
        if shouldThrow { throw IDmeAuthError.keychainError(status: -1) }
        return stored
    }

    func delete() throws {
        if shouldThrow { throw IDmeAuthError.keychainError(status: -1) }
        deleteCallCount += 1
        stored = nil
    }
}
