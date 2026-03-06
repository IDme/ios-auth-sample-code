import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("TokenRefresher")
struct TokenRefresherTests {
    @Test("Successful refresh")
    func refreshSuccessful() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        let response = try await refresher.refresh(refreshToken: "old-refresh-token")

        #expect(response.accessToken == "new-access-token")
        #expect(response.refreshToken == "new-refresh-token")
    }

    @Test("Sends correct body parameters")
    func sendsCorrectBody() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)
        _ = try await refresher.refresh(refreshToken: "refresh-123")

        let request = mockHTTP.capturedRequests.first!
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!

        #expect(bodyString.contains("grant_type=refresh_token"))
        #expect(bodyString.contains("refresh_token=refresh-123"))
        #expect(bodyString.contains("client_id=test-client-id"))
    }

    @Test("Throws on HTTP error")
    func refreshFailure() async {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: "Unauthorized".data(using: .utf8)!, statusCode: 401)

        let refresher = TokenRefresher(configuration: TestFixtures.singleConfig, httpClient: mockHTTP)

        await #expect(throws: IDmeAuthError.self) {
            try await refresher.refresh(refreshToken: "bad-token")
        }
    }
}
