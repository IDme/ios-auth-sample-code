import Foundation
import Security

/// Validates JWT tokens: signature verification (RS256) and claims checking.
struct JWTValidator {
    private let jwksFetcher: JWKSFetching
    private let issuer: String
    private let clientId: String

    init(jwksFetcher: JWKSFetching, issuer: String, clientId: String) {
        self.jwksFetcher = jwksFetcher
        self.issuer = issuer
        self.clientId = clientId
    }

    /// Validates an ID token: decodes, verifies RS256 signature, and checks claims.
    func validate(idToken: String, nonce: String?) async throws {
        let decoded = try JWTDecoder.decode(idToken)

        guard decoded.header.alg == "RS256" else {
            throw IDmeAuthError.invalidJWT(reason: "Unsupported algorithm: \(decoded.header.alg)")
        }

        // Fetch JWKS and find the matching RSA key
        let jwks = try await jwksFetcher.fetchJWKS()
        let rsaKeys = jwks.keys.filter { $0.kty == "RSA" && $0.n != nil && $0.e != nil }
        let jwk: JWK

        if let kid = decoded.header.kid {
            guard let key = rsaKeys.first(where: { $0.kid == kid }) else {
                throw IDmeAuthError.jwksKeyNotFound(kid: kid)
            }
            jwk = key
        } else {
            guard let key = rsaKeys.first else {
                throw IDmeAuthError.invalidJWT(reason: "No RSA keys in JWKS and no kid in JWT header")
            }
            jwk = key
        }

        // Verify RS256 signature
        let publicKey = try RSAKeyConverter.secKey(fromModulus: jwk.n!, exponent: jwk.e!)
        let signedData = Data(decoded.signedPortion.utf8)

        let isValid = SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            signedData as CFData,
            decoded.signatureData as CFData,
            nil
        )

        guard isValid else {
            throw IDmeAuthError.jwtSignatureInvalid
        }

        // Validate claims
        try validateClaims(decoded.payload, nonce: nonce)
    }

    private func validateClaims(_ payload: [String: Any], nonce: String?) throws {
        // Issuer
        if let iss = payload["iss"] as? String {
            guard iss == issuer else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "iss", reason: "Expected \(issuer), got \(iss)")
            }
        }

        // Audience
        if let aud = payload["aud"] as? String {
            guard aud == clientId else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "aud", reason: "Expected \(clientId), got \(aud)")
            }
        } else if let audArray = payload["aud"] as? [String] {
            guard audArray.contains(clientId) else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "aud", reason: "Client ID not in audience array")
            }
        }

        // Expiration
        if let exp = payload["exp"] as? TimeInterval {
            guard Date(timeIntervalSince1970: exp) > Date() else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "exp", reason: "Token has expired")
            }
        }

        // Nonce (OIDC)
        if let expectedNonce = nonce {
            guard let tokenNonce = payload["nonce"] as? String else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "nonce", reason: "Missing nonce in token")
            }
            guard tokenNonce == expectedNonce else {
                throw IDmeAuthError.jwtClaimInvalid(claim: "nonce", reason: "Nonce mismatch")
            }
        }
    }
}
