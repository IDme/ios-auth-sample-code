import Testing
import Foundation
import Security
@testable import IDmeAuthSDK

@Suite("RSAKeyConverter")
struct RSAKeyConverterTests {
    @Test("Creates SecKey from JWK components")
    func secKeyCreation() throws {
        // Well-known RSA 2048 test key (from RFC 7517)
        let n = "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw"
        let e = "AQAB"

        let key = try RSAKeyConverter.secKey(fromModulus: n, exponent: e)

        let attributes = SecKeyCopyAttributes(key) as! [String: Any]
        #expect(attributes[kSecAttrKeyClass as String] as? String == kSecAttrKeyClassPublic as String)
        #expect(attributes[kSecAttrKeyType as String] as? String == kSecAttrKeyTypeRSA as String)
    }

    @Test("Throws on invalid Base64URL input")
    func invalidBase64URLThrows() {
        #expect(throws: IDmeAuthError.self) {
            try RSAKeyConverter.secKey(fromModulus: "!!!invalid!!!", exponent: "AQAB")
        }
    }
}
