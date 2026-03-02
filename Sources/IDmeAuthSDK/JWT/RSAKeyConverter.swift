import Foundation
import Security

/// Converts JWK RSA components (n, e) to a SecKey for signature verification.
enum RSAKeyConverter {
    /// Converts a JWK to a SecKey public key.
    /// - Parameters:
    ///   - n: The RSA modulus as a Base64URL-encoded string.
    ///   - e: The RSA exponent as a Base64URL-encoded string.
    /// - Returns: A SecKey suitable for RS256 verification.
    static func secKey(fromModulus n: String, exponent e: String) throws -> SecKey {
        guard let modulusData = Base64URL.decode(n),
              let exponentData = Base64URL.decode(e) else {
            throw IDmeAuthError.invalidJWT(reason: "Invalid Base64URL in JWK modulus or exponent")
        }

        let derData = buildDERPublicKey(modulus: modulusData, exponent: exponentData)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: modulusData.count * 8
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(derData as CFData, attributes as CFDictionary, &error) else {
            let desc = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw IDmeAuthError.invalidJWT(reason: "Failed to create SecKey: \(desc)")
        }

        return key
    }

    // MARK: - DER Encoding

    /// Builds a DER-encoded RSA public key from modulus and exponent.
    private static func buildDERPublicKey(modulus: Data, exponent: Data) -> Data {
        let modulusEncoded = derEncodeInteger(modulus)
        let exponentEncoded = derEncodeInteger(exponent)
        let sequence = derEncodeSequence(modulusEncoded + exponentEncoded)
        let bitString = derEncodeBitString(sequence)

        // RSA OID: 1.2.840.113549.1.1.1
        let rsaOID: [UInt8] = [
            0x30, 0x0D,  // SEQUENCE
            0x06, 0x09,  // OID
            0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01,
            0x05, 0x00   // NULL
        ]

        return derEncodeSequence(Data(rsaOID) + bitString)
    }

    /// DER-encodes an integer, adding a leading zero byte if the high bit is set.
    private static func derEncodeInteger(_ data: Data) -> Data {
        var bytes = [UInt8](data)

        // Strip leading zeros but keep at least one byte
        while bytes.count > 1 && bytes[0] == 0 {
            bytes.removeFirst()
        }

        // Add leading zero if high bit is set (to indicate positive integer)
        if let first = bytes.first, first & 0x80 != 0 {
            bytes.insert(0x00, at: 0)
        }

        var result = Data([0x02]) // INTEGER tag
        result.append(contentsOf: derEncodeLength(bytes.count))
        result.append(contentsOf: bytes)
        return result
    }

    /// DER-encodes a SEQUENCE.
    private static func derEncodeSequence(_ content: Data) -> Data {
        var result = Data([0x30]) // SEQUENCE tag
        result.append(contentsOf: derEncodeLength(content.count))
        result.append(content)
        return result
    }

    /// DER-encodes a BIT STRING.
    private static func derEncodeBitString(_ content: Data) -> Data {
        var result = Data([0x03]) // BIT STRING tag
        result.append(contentsOf: derEncodeLength(content.count + 1))
        result.append(0x00) // No unused bits
        result.append(content)
        return result
    }

    /// Encodes a length value in DER format.
    private static func derEncodeLength(_ length: Int) -> [UInt8] {
        if length < 0x80 {
            return [UInt8(length)]
        } else if length <= 0xFF {
            return [0x81, UInt8(length)]
        } else {
            return [0x82, UInt8(length >> 8), UInt8(length & 0xFF)]
        }
    }
}
