import Foundation

/// Response from the ID.me `/api/public/v3/attributes.json` endpoint.
///
/// The endpoint returns a JWT whose payload contains `attributes` and `status` arrays.
public struct AttributeResponse: Sendable, Equatable {
    /// The user's verified attributes (e.g. name, email, zip).
    public let attributes: [Attribute]

    /// The user's verification statuses by group.
    public let status: [VerificationStatus]

    public struct Attribute: Codable, Sendable, Equatable {
        /// Machine-readable key (e.g. "fname", "lname", "email", "uuid", "zip").
        public let handle: String

        /// Human-readable label (e.g. "First Name").
        public let name: String

        /// The attribute value.
        public let value: String?
    }

    public struct VerificationStatus: Codable, Sendable, Equatable {
        /// The verification group (e.g. "military", "student").
        public let group: String

        /// Subgroups within the group (e.g. ["Service Member", "Veteran"]).
        public let subgroups: [String]?

        /// Whether the user is verified for this group.
        public let verified: Bool
    }
}

extension AttributeResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case attributes
        case status
    }

    public init(from decoder: Decoder) throws {
        // Try the expected { "attributes": [...], "status": [...] } format first
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let attrs = try? container.decodeIfPresent([Attribute].self, forKey: .attributes) {
            self.attributes = attrs
            self.status = (try? container.decodeIfPresent([VerificationStatus].self, forKey: .status)) ?? []
            return
        }

        // Fallback: the payload may be flat JWT claims — wrap all string values as attributes
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var attrs: [Attribute] = []
        for key in container.allKeys {
            if let value = try? container.decode(String.self, forKey: key) {
                attrs.append(Attribute(handle: key.stringValue, name: key.stringValue, value: value))
            }
        }
        self.attributes = attrs

        // Try to decode status even in fallback mode
        let statusContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.status = (try? statusContainer.decodeIfPresent([VerificationStatus].self, forKey: .status)) ?? []
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
