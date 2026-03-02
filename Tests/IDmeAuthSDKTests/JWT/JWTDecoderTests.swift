import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("JWTDecoder")
struct JWTDecoderTests {
    @Test("Decodes a valid JWT")
    func decodeValid() throws {
        let header = Base64URL.encode("""
        {"alg":"RS256","kid":"test-kid","typ":"JWT"}
        """.data(using: .utf8)!)

        let payload = Base64URL.encode("""
        {"sub":"user-123","iss":"https://api.id.me","aud":"client-id","exp":9999999999}
        """.data(using: .utf8)!)

        let signature = Base64URL.encode(Data(repeating: 0xAB, count: 32))

        let jwt = "\(header).\(payload).\(signature)"
        let decoded = try JWTDecoder.decode(jwt)

        #expect(decoded.header.alg == "RS256")
        #expect(decoded.header.kid == "test-kid")
        #expect(decoded.payload["sub"] as? String == "user-123")
        #expect(decoded.payload["iss"] as? String == "https://api.id.me")
        #expect(decoded.signedPortion == "\(header).\(payload)")
    }

    @Test("Rejects JWT with missing parts")
    func rejectsMissingParts() {
        #expect(throws: IDmeAuthError.self) {
            try JWTDecoder.decode("header.payload")
        }
    }

    @Test("Rejects JWT with invalid header")
    func rejectsInvalidHeader() {
        #expect(throws: IDmeAuthError.self) {
            try JWTDecoder.decode("not-valid-base64.payload.signature")
        }
    }

    @Test("Rejects JWT with missing alg")
    func rejectsMissingAlg() {
        let header = Base64URL.encode("""
        {"kid":"test-kid","typ":"JWT"}
        """.data(using: .utf8)!)
        let payload = Base64URL.encode("{}".data(using: .utf8)!)
        let signature = Base64URL.encode(Data([0x01]))

        let jwt = "\(header).\(payload).\(signature)"
        #expect(throws: IDmeAuthError.self) {
            try JWTDecoder.decode(jwt)
        }
    }

    @Test("Decodes JWT without kid")
    func decodesWithoutKid() throws {
        let header = Base64URL.encode("""
        {"alg":"RS256","typ":"JWT"}
        """.data(using: .utf8)!)
        let payload = Base64URL.encode("""
        {"sub":"user-123"}
        """.data(using: .utf8)!)
        let signature = Base64URL.encode(Data([0x01]))

        let jwt = "\(header).\(payload).\(signature)"
        let decoded = try JWTDecoder.decode(jwt)

        #expect(decoded.header.alg == "RS256")
        #expect(decoded.header.kid == nil)
    }
}
