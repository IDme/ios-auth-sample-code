import Foundation

/// The integration pattern for verification.
public enum IDmeVerificationType: String, Sendable {
    /// Single scope/policy — routes to `/oauth/authorize`.
    /// Use when the integration targets a single verification community.
    case single

    /// Multiple scopes/policies — routes to `groups.id.me`.
    /// Presents a UI for the user to choose their verification community.
    /// **Production only** — SDK throws an error if combined with `.sandbox`.
    case groups
}
