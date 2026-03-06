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

    @Test("Always includes PKCE code challenge")
    func includesCodeChallenge() throws {
        let config = TestFixtures.singleConfig
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["code_challenge"] != nil)
        #expect(params["code_challenge_method"] == "S256")
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
            scopes: [.military, .student],
            verificationType: .single
        )
        let request = try AuthorizationRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let scopeParam = queryItems.first(where: { $0.name == "scope" })?.value ?? ""

        #expect(scopeParam.contains("military"))
        #expect(scopeParam.contains("student"))
    }
}
