import Foundation
import CryptoKit

/// Generates PKCE code verifier and challenge per RFC 7636.
struct PKCEGenerator: Sendable {
    /// The code verifier (43-128 character URL-safe string).
    let codeVerifier: String

    /// The S256 code challenge derived from the verifier.
    let codeChallenge: String

    /// The challenge method (always "S256").
    let codeChallengeMethod = "S256"

    init() {
        let verifier = Self.generateVerifier()
        self.codeVerifier = verifier
        self.codeChallenge = Self.generateChallenge(from: verifier)
    }

    /// Initializes with a known verifier (for testing).
    init(codeVerifier: String) {
        self.codeVerifier = codeVerifier
        self.codeChallenge = Self.generateChallenge(from: codeVerifier)
    }

    /// Generates a cryptographically random code verifier.
    private static func generateVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Base64URL.encode(Data(bytes))
    }

    /// Generates an S256 code challenge from the verifier.
    static func generateChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Base64URL.encode(Data(hash))
    }
}
