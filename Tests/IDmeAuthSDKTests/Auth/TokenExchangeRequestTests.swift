import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("TokenExchangeRequest")
struct TokenExchangeRequestTests {
    @Test("Successful token exchange")
    func exchangeSuccessful() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let config = TestFixtures.singleConfig
        let exchange = TokenExchangeRequest(configuration: config, httpClient: mockHTTP)

        let response = try await exchange.exchange(code: "test-code", codeVerifier: "test-verifier")

        #expect(response.accessToken == "new-access-token")
        #expect(response.refreshToken == "new-refresh-token")
        #expect(response.tokenType == "Bearer")
        #expect(response.expiresIn == 3600)
    }

    @Test("Sends correct body parameters")
    func sendsCorrectBody() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let config = TestFixtures.singleConfig
        let exchange = TokenExchangeRequest(configuration: config, httpClient: mockHTTP)

        _ = try await exchange.exchange(code: "auth-code", codeVerifier: "verifier-123")

        let request = mockHTTP.capturedRequests.first!
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!

        #expect(bodyString.contains("grant_type=authorization_code"))
        #expect(bodyString.contains("code=auth-code"))
        #expect(bodyString.contains("code_verifier=verifier-123"))
        #expect(bodyString.contains("client_id=test-client-id"))
    }

    @Test("Includes client secret when configured")
    func includesClientSecret() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let config = TestFixtures.oauthConfig
        let exchange = TokenExchangeRequest(configuration: config, httpClient: mockHTTP)

        _ = try await exchange.exchange(code: "auth-code", codeVerifier: nil)

        let request = mockHTTP.capturedRequests.first!
        let bodyString = String(data: request.httpBody!, encoding: .utf8)!

        #expect(bodyString.contains("client_secret=test-client-secret"))
    }

    @Test("Throws on HTTP error")
    func exchangeFailure() async {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: "Bad Request".data(using: .utf8)!, statusCode: 400)

        let config = TestFixtures.singleConfig
        let exchange = TokenExchangeRequest(configuration: config, httpClient: mockHTTP)

        await #expect(throws: IDmeAuthError.self) {
            try await exchange.exchange(code: "bad-code", codeVerifier: nil)
        }
    }

    @Test("Uses correct sandbox endpoint")
    func sandboxEndpoint() async throws {
        let mockHTTP = MockHTTPClient()
        mockHTTP.enqueue(data: TestFixtures.tokenResponseJSON, statusCode: 200)

        let config = TestFixtures.sandboxConfig
        let exchange = TokenExchangeRequest(configuration: config, httpClient: mockHTTP)

        _ = try await exchange.exchange(code: "code", codeVerifier: nil)

        let request = mockHTTP.capturedRequests.first!
        #expect(request.url!.absoluteString.contains("api.idmelabs.com/oauth/token"))
    }
}
