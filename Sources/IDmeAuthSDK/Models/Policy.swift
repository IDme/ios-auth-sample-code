import Foundation

/// A verification policy available for the organization.
///
/// Returned by the `/api/public/v3/policies` endpoint.
/// The policy `handle` is used as the OAuth `scope` parameter.
public struct Policy: Codable, Sendable, Equatable, Identifiable {
    /// Human-readable name (e.g. "Military Verification").
    public let name: String

    /// Machine-readable handle used as the OAuth scope (e.g. "military").
    public let handle: String

    /// Whether the policy is currently active.
    public let active: Bool

    /// Groups contained within this policy.
    public let groups: [Group]

    public var id: String { handle }

    public init(name: String, handle: String, active: Bool, groups: [Group]) {
        self.name = name
        self.handle = handle
        self.active = active
        self.groups = groups
    }

    public struct Group: Codable, Sendable, Equatable {
        /// Human-readable group name (e.g. "Military").
        public let name: String

        /// Machine-readable group handle.
        public let handle: String

        /// Subgroups within this group.
        public let subgroups: [Group]?
    }
}
