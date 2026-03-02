import Foundation
@testable import IDmeAuthSDK

@MainActor
final class MockWebAuthSession: WebAuthSessionProtocol {
    var callbackURL: URL?
    var error: Error?
    var capturedURL: URL?
    var capturedScheme: String?

    func authenticate(url: URL, callbackScheme: String?) async throws -> URL {
        capturedURL = url
        capturedScheme = callbackScheme
        if let error {
            throw error
        }
        guard let callbackURL else {
            throw IDmeAuthError.invalidCallbackURL
        }
        return callbackURL
    }
}
