import Testing
import Foundation
@testable import IDmeAuthSDK

@Suite("GroupsRequest")
struct GroupsRequestTests {
    @Test("URL contains required params")
    func requiredParams() throws {
        let config = TestFixtures.groupsConfig
        let request = try GroupsRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["client_id"] == config.clientId)
        #expect(params["redirect_uri"] == config.redirectURI)
        #expect(params["response_type"] == "code")
        #expect(params["state"] != nil)
    }

    @Test("Uses comma-separated scopes")
    func commaSeparatedScopes() throws {
        let config = TestFixtures.groupsConfig
        let request = try GroupsRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let scopeParam = queryItems.first(where: { $0.name == "scopes" })?.value ?? ""

        #expect(scopeParam.contains("military"))
        #expect(scopeParam.contains("first_responder"))
        #expect(scopeParam.contains(","))
    }

    @Test("Uses plural 'scopes' parameter name")
    func pluralScopesParam() throws {
        let config = TestFixtures.groupsConfig
        let request = try GroupsRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []

        #expect(queryItems.first(where: { $0.name == "scopes" }) != nil)
        #expect(queryItems.first(where: { $0.name == "scope" }) == nil)
    }

    @Test("Uses groups.id.me domain")
    func groupsDomain() throws {
        let config = TestFixtures.groupsConfig
        let request = try GroupsRequest(configuration: config)
        #expect(request.url.absoluteString.contains("groups.id.me"))
    }

    @Test("Throws error in sandbox environment")
    func throwsInSandbox() {
        let config = IDmeConfiguration(
            clientId: "test",
            redirectURI: "testapp://callback",
            scopes: [.military],
            environment: .sandbox,
            verificationType: .groups
        )

        #expect(throws: IDmeAuthError.groupsNotAvailableInSandbox) {
            try GroupsRequest(configuration: config)
        }
    }

    @Test("Includes PKCE code challenge")
    func includesPKCE() throws {
        let config = TestFixtures.groupsConfig
        let request = try GroupsRequest(configuration: config)

        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })

        #expect(params["code_challenge"] != nil)
        #expect(params["code_challenge_method"] == "S256")
    }
}
