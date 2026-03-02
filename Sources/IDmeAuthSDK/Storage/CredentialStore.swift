import Foundation

/// Protocol for credential persistence, enabling mock injection in tests.
protocol CredentialStoring: Sendable {
    func save(_ credentials: Credentials) throws
    func load() throws -> Credentials?
    func delete() throws
}

/// Persists `Credentials` to the iOS Keychain.
struct CredentialStore: CredentialStoring {
    private static let credentialsKey = "idme_credentials"
    private let keychain: KeychainStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    func save(_ credentials: Credentials) throws {
        let data = try encoder.encode(credentials)
        try keychain.save(data: data, forKey: Self.credentialsKey)
        Log.debug("Credentials saved to keychain")
    }

    func load() throws -> Credentials? {
        guard let data = try keychain.load(forKey: Self.credentialsKey) else {
            return nil
        }
        return try decoder.decode(Credentials.self, from: data)
    }

    func delete() throws {
        try keychain.delete(forKey: Self.credentialsKey)
        Log.debug("Credentials deleted from keychain")
    }
}
