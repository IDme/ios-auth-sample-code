import Foundation
@testable import IDmeAuthSDK

final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var responses: [(Data, HTTPURLResponse)] = []
    var capturedRequests: [URLRequest] = []
    private var callIndex = 0

    func enqueue(data: Data, statusCode: Int, url: URL = URL(string: "https://example.com")!) {
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        responses.append((data, response))
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequests.append(request)
        guard callIndex < responses.count else {
            throw IDmeAuthError.networkError(underlying: "No mock response available")
        }
        let response = responses[callIndex]
        callIndex += 1
        return response
    }
}
