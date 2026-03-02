import Foundation

/// Actor that manages token lifecycle: storage, retrieval, and refresh.
/// Coalesces concurrent refresh requests into a single network call.
actor TokenManager {
    private let credentialStore: CredentialStoring
    private let refresher: TokenRefreshing
    private var cachedCredentials: Credentials?
    private var refreshTask: Task<Credentials, Error>?

    init(credentialStore: CredentialStoring, refresher: TokenRefreshing) {
        self.credentialStore = credentialStore
        self.refresher = refresher
    }

    /// Returns stored credentials, loading from keychain if necessary.
    func currentCredentials() throws -> Credentials? {
        if let cached = cachedCredentials {
            return cached
        }
        let loaded = try credentialStore.load()
        cachedCredentials = loaded
        return loaded
    }

    /// Stores new credentials in both memory and keychain.
    func store(_ credentials: Credentials) throws {
        cachedCredentials = credentials
        try credentialStore.save(credentials)
    }

    /// Returns valid credentials, refreshing if they expire within `minTTL` seconds.
    /// Coalesces concurrent refresh calls into a single network request.
    func validCredentials(minTTL: TimeInterval = 60) async throws -> Credentials {
        guard let credentials = try currentCredentials() else {
            throw IDmeAuthError.notAuthenticated
        }

        guard credentials.expiresWithin(seconds: minTTL) else {
            return credentials
        }

        // Coalesce concurrent refresh requests
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        guard let refreshToken = credentials.refreshToken else {
            throw IDmeAuthError.refreshTokenExpired
        }

        let task = Task<Credentials, Error> {
            let tokenResponse = try await refresher.refresh(refreshToken: refreshToken)
            let newCredentials = tokenResponse.toCredentials()
            try self.store(newCredentials)
            return newCredentials
        }

        refreshTask = task

        do {
            let result = try await task.value
            refreshTask = nil
            return result
        } catch {
            refreshTask = nil
            throw error
        }
    }

    /// Clears all stored credentials.
    func clear() throws {
        cachedCredentials = nil
        refreshTask?.cancel()
        refreshTask = nil
        try credentialStore.delete()
    }
}
