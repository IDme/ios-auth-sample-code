import Foundation

/// JSON Web Key Set response.
struct JWKS: Codable, Sendable {
    let keys: [JWK]
}

/// A single JSON Web Key.
struct JWK: Codable, Sendable {
    let kty: String
    let kid: String?
    let use: String?
    let alg: String?
    let n: String?  // RSA modulus (Base64URL) — nil for non-RSA keys
    let e: String?  // RSA exponent (Base64URL) — nil for non-RSA keys
}
