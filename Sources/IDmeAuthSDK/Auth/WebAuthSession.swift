import AuthenticationServices
import Foundation

#if canImport(UIKit)
import UIKit
public typealias PresentationAnchor = UIWindow
#elseif canImport(AppKit)
import AppKit
public typealias PresentationAnchor = NSWindow
#endif

/// Protocol for the web authentication session, enabling mock injection in tests.
@MainActor
protocol WebAuthSessionProtocol: Sendable {
    func authenticate(url: URL, callbackScheme: String?) async throws -> URL
}

/// Wrapper around ASWebAuthenticationSession.
@MainActor
final class WebAuthSession: NSObject, WebAuthSessionProtocol, ASWebAuthenticationPresentationContextProviding {
    private weak var anchor: PresentationAnchor?

    init(anchor: PresentationAnchor) {
        self.anchor = anchor
    }

    func authenticate(url: URL, callbackScheme: String?) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: IDmeAuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: IDmeAuthError.networkError(underlying: error.localizedDescription))
                    }
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: IDmeAuthError.invalidCallbackURL)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.start()
        }
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            anchor ?? ASPresentationAnchor()
        }
    }
}
