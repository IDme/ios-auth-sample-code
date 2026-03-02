import Foundation
import Security

/// Generates a cryptographically random nonce for OIDC flows.
struct NonceGenerator: Sendable {
    /// Generates a random nonce string.
    static func generate() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Base64URL.encode(Data(bytes))
    }
}
