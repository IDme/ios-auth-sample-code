import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("Base64URL")
struct Base64URLTests {
    @Test("Encodes empty data")
    func encodeEmpty() {
        #expect(Base64URL.encode(Data()) == "")
    }

    @Test("Round-trip encode/decode")
    func roundTrip() {
        let original = "Hello, World! This is a test string for Base64URL encoding."
        let data = original.data(using: .utf8)!
        let encoded = Base64URL.encode(data)
        let decoded = Base64URL.decode(encoded)
        #expect(decoded == data)
    }

    @Test("No padding characters in output")
    func noPadding() {
        let data = Data([0x01, 0x02, 0x03])
        let encoded = Base64URL.encode(data)
        #expect(!encoded.contains("="))
    }

    @Test("Uses URL-safe characters")
    func urlSafeCharacters() {
        let data = Data([0xFB, 0xFF, 0xFE])
        let encoded = Base64URL.encode(data)
        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
    }

    @Test("Decodes strings without padding")
    func decodeWithoutPadding() {
        let decoded = Base64URL.decode("YQ")
        #expect(decoded == "a".data(using: .utf8))
    }

    @Test("Returns nil for invalid input")
    func decodeInvalid() {
        let decoded = Base64URL.decode("!!!!")
        #expect(decoded == nil)
    }

    @Test("Known test vectors")
    func knownValues() {
        #expect(Base64URL.encode("f".data(using: .utf8)!) == "Zg")
        #expect(Base64URL.encode("fo".data(using: .utf8)!) == "Zm8")
        #expect(Base64URL.encode("foo".data(using: .utf8)!) == "Zm9v")
    }
}
