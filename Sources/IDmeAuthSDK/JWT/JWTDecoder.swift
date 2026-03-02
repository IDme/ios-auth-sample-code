import Foundation

/// Decoded JWT components.
struct DecodedJWT: @unchecked Sendable {
    let header: JWTHeader
    let payload: [String: Any]
    let signatureData: Data
    let signedPortion: String // "header.payload" for signature verification

    struct JWTHeader: Sendable {
        let alg: String
        let kid: String?
    }
}

/// Decodes a JWT string into its header, payload, and signature components.
enum JWTDecoder {
    static func decode(_ token: String) throws -> DecodedJWT {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw IDmeAuthError.invalidJWT(reason: "JWT must have 3 parts, found \(parts.count)")
        }

        let headerPart = String(parts[0])
        let payloadPart = String(parts[1])
        let signaturePart = String(parts[2])

        // Decode header
        guard let headerData = Base64URL.decode(headerPart),
              let headerJSON = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] else {
            throw IDmeAuthError.invalidJWT(reason: "Failed to decode JWT header")
        }

        guard let alg = headerJSON["alg"] as? String else {
            throw IDmeAuthError.invalidJWT(reason: "Missing 'alg' in JWT header")
        }

        let kid = headerJSON["kid"] as? String

        // Decode payload
        guard let payloadData = Base64URL.decode(payloadPart),
              let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw IDmeAuthError.invalidJWT(reason: "Failed to decode JWT payload")
        }

        // Decode signature
        guard let signatureData = Base64URL.decode(signaturePart) else {
            throw IDmeAuthError.invalidJWT(reason: "Failed to decode JWT signature")
        }

        let signedPortion = "\(headerPart).\(payloadPart)"

        return DecodedJWT(
            header: DecodedJWT.JWTHeader(alg: alg, kid: kid),
            payload: payloadJSON,
            signatureData: signatureData,
            signedPortion: signedPortion
        )
    }
}
