import Foundation

/// Protocol for fetching JWKS, enabling mock injection.
protocol JWKSFetching: Sendable {
    func fetchJWKS() async throws -> JWKS
}

/// Fetches and caches the JSON Web Key Set from ID.me.
actor JWKSClient: JWKSFetching {
    private let environment: IDmeEnvironment
    private let httpClient: HTTPClient
    private var cached: JWKS?
    private var cacheDate: Date?
    private let cacheTTL: TimeInterval

    init(
        environment: IDmeEnvironment,
        httpClient: HTTPClient = URLSessionHTTPClient(),
        cacheTTL: TimeInterval = 3600
    ) {
        self.environment = environment
        self.httpClient = httpClient
        self.cacheTTL = cacheTTL
    }

    func fetchJWKS() async throws -> JWKS {
        if let cached, let cacheDate, Date().timeIntervalSince(cacheDate) < cacheTTL {
            return cached
        }

        let url = APIEndpoint.jwks(environment: environment)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch let error as IDmeAuthError {
            throw error
        } catch {
            throw IDmeAuthError.networkError(underlying: error.localizedDescription)
        }

        guard (200...299).contains(response.statusCode) else {
            throw IDmeAuthError.unexpectedResponse(statusCode: response.statusCode)
        }

        let jwks: JWKS
        do {
            jwks = try JSONDecoder().decode(JWKS.self, from: data)
        } catch {
            throw IDmeAuthError.decodingFailed(underlying: error.localizedDescription)
        }

        self.cached = jwks
        self.cacheDate = Date()

        return jwks
    }
}
