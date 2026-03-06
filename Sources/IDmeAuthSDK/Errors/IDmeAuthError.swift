import Foundation

/// All errors thrown by the IDmeAuthSDK.
public enum IDmeAuthError: Error, Sendable, Equatable {
    // MARK: - Configuration

    /// The groups verification type is only available in production.
    case groupsNotAvailableInSandbox

    /// The redirect URI is invalid.
    case invalidRedirectURI

    // MARK: - Auth Flow

    /// The user cancelled the authentication session.
    case userCancelled

    /// The state parameter in the callback did not match the original request.
    case stateMismatch

    /// No authorization code was found in the callback URL.
    case missingAuthorizationCode

    /// The callback URL could not be parsed.
    case invalidCallbackURL

    // MARK: - Token

    /// The token exchange request failed.
    case tokenExchangeFailed(statusCode: Int, message: String)

    /// No credentials are available (user not logged in).
    case notAuthenticated

    /// The refresh token is missing or expired.
    case refreshTokenExpired

    /// Token refresh failed.
    case tokenRefreshFailed(statusCode: Int, message: String)

    // MARK: - JWT

    /// The JWT string is malformed.
    case invalidJWT(reason: String)

    // MARK: - Network

    /// A network request failed.
    case networkError(underlying: String)

    /// The server returned an unexpected response.
    case unexpectedResponse(statusCode: Int)

    /// The response body could not be decoded.
    case decodingFailed(underlying: String)

    // MARK: - Keychain

    /// A Keychain operation failed.
    case keychainError(status: Int32)

    public static func == (lhs: IDmeAuthError, rhs: IDmeAuthError) -> Bool {
        switch (lhs, rhs) {
        case (.groupsNotAvailableInSandbox, .groupsNotAvailableInSandbox),
             (.invalidRedirectURI, .invalidRedirectURI),
             (.userCancelled, .userCancelled),
             (.stateMismatch, .stateMismatch),
             (.missingAuthorizationCode, .missingAuthorizationCode),
             (.invalidCallbackURL, .invalidCallbackURL),
             (.notAuthenticated, .notAuthenticated),
             (.refreshTokenExpired, .refreshTokenExpired):
            return true
        case let (.tokenExchangeFailed(l1, l2), .tokenExchangeFailed(r1, r2)):
            return l1 == r1 && l2 == r2
        case let (.tokenRefreshFailed(l1, l2), .tokenRefreshFailed(r1, r2)):
            return l1 == r1 && l2 == r2
        case let (.invalidJWT(l), .invalidJWT(r)):
            return l == r
        case let (.networkError(l), .networkError(r)):
            return l == r
        case let (.unexpectedResponse(l), .unexpectedResponse(r)):
            return l == r
        case let (.decodingFailed(l), .decodingFailed(r)):
            return l == r
        case let (.keychainError(l), .keychainError(r)):
            return l == r
        default:
            return false
        }
    }
}

extension IDmeAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .groupsNotAvailableInSandbox:
            return "The groups verification type is only available in production."
        case .invalidRedirectURI:
            return "The redirect URI is invalid."
        case .userCancelled:
            return "The user cancelled the authentication session."
        case .stateMismatch:
            return "The state parameter did not match. Possible CSRF attack."
        case .missingAuthorizationCode:
            return "No authorization code was found in the callback."
        case .invalidCallbackURL:
            return "The callback URL could not be parsed."
        case let .tokenExchangeFailed(statusCode, message):
            return "Token exchange failed (\(statusCode)): \(message)"
        case .notAuthenticated:
            return "No credentials available. Please log in first."
        case .refreshTokenExpired:
            return "The refresh token is missing or expired."
        case let .tokenRefreshFailed(statusCode, message):
            return "Token refresh failed (\(statusCode)): \(message)"
        case let .invalidJWT(reason):
            return "Invalid JWT: \(reason)"
        case let .networkError(underlying):
            return "Network error: \(underlying)"
        case let .unexpectedResponse(statusCode):
            return "Unexpected server response (\(statusCode))."
        case let .decodingFailed(underlying):
            return "Decoding failed: \(underlying)"
        case let .keychainError(status):
            return "Keychain error (status: \(status))."
        }
    }
}
