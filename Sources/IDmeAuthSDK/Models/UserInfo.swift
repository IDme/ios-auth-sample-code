import Foundation

/// User profile information returned from the ID.me UserInfo endpoint.
public struct UserInfo: Codable, Sendable, Equatable {
    /// The user's unique identifier.
    public let sub: String?

    /// The user's email address.
    public let email: String?

    /// Whether the user's email is verified.
    public let emailVerified: Bool?

    /// The user's given (first) name.
    public let givenName: String?

    /// The user's family (last) name.
    public let familyName: String?

    /// The user's full name.
    public let name: String?

    /// The user's profile picture URL.
    public let picture: String?

    enum CodingKeys: String, CodingKey {
        case sub
        case email
        case emailVerified = "email_verified"
        case givenName = "given_name"
        case familyName = "family_name"
        case name
        case picture
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sub = try container.decodeIfPresent(String.self, forKey: .sub)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        givenName = try container.decodeIfPresent(String.self, forKey: .givenName)
        familyName = try container.decodeIfPresent(String.self, forKey: .familyName)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        picture = try container.decodeIfPresent(String.self, forKey: .picture)

        // email_verified may be a Bool or a String ("true"/"false")
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .emailVerified) {
            emailVerified = boolValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .emailVerified) {
            emailVerified = stringValue.lowercased() == "true"
        } else {
            emailVerified = nil
        }
    }
}
