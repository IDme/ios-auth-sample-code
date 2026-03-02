import Foundation
import Security

/// Generates a cryptographically random state parameter for CSRF protection.
struct StateGenerator: Sendable {
    /// Generates a random state string.
    static func generate() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Base64URL.encode(Data(bytes))
    }
}
