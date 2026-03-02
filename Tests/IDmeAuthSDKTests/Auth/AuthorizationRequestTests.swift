import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("AuthorizationRequest")
struct AuthorizationRequestTests {
    @Test("URL contains required OAuth params")
    func requiredParams() throws {
        let config = TestFixtures.singleConfig
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["client_id"] == config.clientId)
        #expect(params["redirect_uri"] == config.redirectURI)
        #expect(params["response_type"] == "code")
        #expect(params["scope"] == "military")
        #expect(params["state"] != nil)
    }

    @Test("PKCE mode includes code challenge")
    func pkceIncludesCodeChallenge() throws {
        let config = TestFixtures.singleConfig
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["code_challenge"] != nil)
        #expect(params["code_challenge_method"] == "S256")
        #expect(request.pkce != nil)
    }

    @Test("OAuth mode does not include PKCE")
    func oauthNoPKCE() throws {
        let config = TestFixtures.oauthConfig
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["code_challenge"] == nil)
        #expect(request.pkce == nil)
    }

    @Test("OIDC mode includes nonce")
    func oidcIncludesNonce() throws {
        let config = TestFixtures.oidcConfig
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["nonce"] != nil)
        #expect(request.nonce != nil)
    }

    @Test("Sandbox uses idmelabs URL")
    func sandboxURL() throws {
        let config = TestFixtures.sandboxConfig
        let request = try AuthorizationRequest(configuration: config)
        #expect(request.url.absoluteString.contains("api.idmelabs.com"))
    }

    @Test("Production uses id.me URL")
    func productionURL() throws {
        let config = TestFixtures.singleConfig
        let request = try AuthorizationRequest(configuration: config)
        #expect(request.url.absoluteString.contains("api.id.me"))
    }

    @Test("Multiple scopes are space-separated")
    func multipleScopesSpaceSeparated() throws {
        let config = IDmeConfiguration(
            clientId: "test",
            redirectURI: "testapp://callback",
            scopes: [.openid, .profile, .military],
            authMode: .oauthPKCE,
            verificationType: .single
        )
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let scopeParam = queryItems.first(where: { $0.name == "scope" })?.value ?? ""

        #expect(scopeParam.contains("openid"))
        #expect(scopeParam.contains("profile"))
        #expect(scopeParam.contains("military"))
    }
}
