import Foundation

/// Abstraction over HTTP networking for testability.
protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Production HTTP client backed by URLSession.
struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IDmeAuthError.networkError(underlying: "Response is not an HTTP response")
        }
        return (data, httpResponse)
    }
}
