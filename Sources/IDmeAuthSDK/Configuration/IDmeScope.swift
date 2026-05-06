import Foundation

/// Type-safe OAuth scopes supported by ID.me.
public enum IDmeScope: String, Sendable, CaseIterable {
    case login
    case nistIal2Aal2 = "http://idmanagement.gov/ns/assurance/ial/2/aal/2"
    case military
    case firstResponder = "first_responder"
    case nurse
    case teacher
    case student
    case governmentEmployee = "government"
    case lowIncome = "low_income"

    /// Space-separated scope string for the authorize endpoint.
    static func authorizeString(from scopes: [IDmeScope]) -> String {
        scopes.map(\.rawValue).joined(separator: " ")
    }

    /// Comma-separated scope string for the groups endpoint.
    static func groupsString(from scopes: [IDmeScope]) -> String {
        scopes.map(\.rawValue).joined(separator: ",")
    }
}
