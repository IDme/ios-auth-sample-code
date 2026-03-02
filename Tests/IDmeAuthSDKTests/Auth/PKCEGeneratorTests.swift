import Testing
import CryptoKit
import Foundation
@testable import IDmeAuthSDK

@Suite("PKCEGenerator")
struct PKCEGeneratorTests {
    @Test("Code verifier is 43 characters (Base64URL of 32 bytes)")
    func codeVerifierLength() {
        let pkce = PKCEGenerator()
        #expect(pkce.codeVerifier.count == 43)
    }

    @Test("Code verifier contains only URL-safe characters")
    func codeVerifierIsURLSafe() {
        let pkce = PKCEGenerator()
        let urlSafe = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        #expect(pkce.codeVerifier.unicodeScalars.allSatisfy { urlSafe.contains($0) })
    }

    @Test("Code challenge is SHA256 of the verifier")
    func codeChallengeIsSHA256OfVerifier() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let pkce = PKCEGenerator(codeVerifier: verifier)

        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        let expected = Base64URL.encode(Data(hash))

        #expect(pkce.codeChallenge == expected)
    }

    @Test("Challenge method is S256")
    func codeChallengeMethodIsS256() {
        let pkce = PKCEGenerator()
        #expect(pkce.codeChallengeMethod == "S256")
    }

    @Test("Different instances produce different verifiers")
    func differentVerifiers() {
        let pkce1 = PKCEGenerator()
        let pkce2 = PKCEGenerator()
        #expect(pkce1.codeVerifier != pkce2.codeVerifier)
    }

    @Test("RFC 7636 Appendix B test vector")
    func knownTestVector() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        let pkce = PKCEGenerator(codeVerifier: verifier)
        #expect(pkce.codeChallenge == expectedChallenge)
    }
}
