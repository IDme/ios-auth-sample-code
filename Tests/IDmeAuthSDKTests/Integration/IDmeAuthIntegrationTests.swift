import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("IDmeAuth Integration")
@MainActor
struct IDmeAuthIntegrationTests {
    @Test("Login flow with single scope")
    func loginSingleScope() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let idme = IDmeAuth(
            configuration: TestFixtures.singleConfig,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        let mockSession = MockWebAuthSession()
        mockSession.callbackURL = URL(string: "\(TestFixtures.redirectURI)?code=auth-code-123")!

        let credentials = try await idme.login(webSession: mockSession)

        #expect(credentials.accessToken == "new-access-token")
        #expect(credentials.refreshToken == "new-refresh-token")
        #expect(mockSession.capturedURL != nil)

        let capturedURL = mockSession.capturedURL!
        #expect(capturedURL.absoluteString.contains("api.id.me/oauth/authorize"))
        #expect(capturedURL.absoluteString.contains("client_id=test-client-id"))
        #expect(capturedURL.absoluteString.contains("scope=military"))
    }

    @Test("Login flow with groups scope")
    func loginGroupsScope() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: TestFixtures.groupsConfig, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let idme = IDmeAuth(
            configuration: TestFixtures.groupsConfig,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        let mockSession = MockWebAuthSession()
        mockSession.callbackURL = URL(string: "\(TestFixtures.redirectURI)?code=groups-code-456")!

        let credentials = try await idme.login(webSession: mockSession)

        #expect(credentials.accessToken == "new-access-token")

        let capturedURL = mockSession.capturedURL!
        #expect(capturedURL.absoluteString.contains("groups.id.me"))
        #expect(capturedURL.absoluteString.contains("scopes="))
    }

    @Test("Rejects groups in sandbox")
    func rejectsGroupsInSandbox() async {
        let config = IDmeConfiguration(
            clientId: "test",
            redirectURI: "testapp://callback",
            scopes: [.military],
            environment: .sandbox,
            verificationType: .groups
        )

        let mockHTTP = MockHTTPClient()
        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: config, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let idme = IDmeAuth(
            configuration: config,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        let mockSession = MockWebAuthSession()
        mockSession.callbackURL = URL(string: "testapp://callback?code=test")!

        await #expect(throws: IDmeAuthError.self) {
            try await idme.login(webSession: mockSession)
        }
    }

    @Test("User cancelled login")
    func userCancelled() async {
        let mockHTTP = MockHTTPClient()
        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let idme = IDmeAuth(
            configuration: TestFixtures.singleConfig,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        let mockSession = MockWebAuthSession()
        mockSession.error = IDmeAuthError.userCancelled

        await #expect(throws: IDmeAuthError.self) {
            try await idme.login(webSession: mockSession)
        }
    }

    @Test("Fetches user attributes")
    func attributesFetch() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.attributesJSON, statusCode: 200)

        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let creds = TestFixtures.makeCredentials()
        try await tokenManager.store(creds)

        let idme = IDmeAuth(
            configuration: TestFixtures.singleConfig,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        let attrs = try await idme.attributes()

        #expect(attrs.attributes.count == 2)
        #expect(attrs.attributes.first?.handle == "uuid")
        #expect(attrs.status.first?.group == "military")
        #expect(attrs.status.first?.verified == true)

        let request = mockHTTP.capturedRequests.first!
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-access-token")
    }

    @Test("Logout clears credentials")
    func logout() async throws {
        let mockHTTP = MockHTTPClient()
        let mockStore = MockCredentialStore()
        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        let tokenManager = TokenManager(credentialStore: mockStore, refresher: refresher)

        let creds = TestFixtures.makeCredentials()
        try await tokenManager.store(creds)

        let idme = IDmeAuth(
            configuration: TestFixtures.singleConfig,
            tokenManager: tokenManager,
            httpClient: mockHTTP
        )

        idme.logout()

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(mockStore.deleteCallCount == 1)
    }

    @Test("SDK version is set")
    func sdkVersion() {
        #expect(IDmeAuthSDK.version == "1.0.0")
    }
}
