import Foundation

/// OIDC discovery document from `.well-known/openid-configuration`.
struct OIDCDiscovery: Codable, Sendable {
    let issuer: String
    let authorizationEndpoint: String
    let tokenEndpoint: String
    let userinfoEndpoint: String
    let jwksUri: String

    enum CodingKeys: String, CodingKey {
        case issuer
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case userinfoEndpoint = "userinfo_endpoint"
        case jwksUri = "jwks_uri"
    }
}
