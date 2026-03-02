import Foundation
import IDmeAuthSDK
import Observation
import UIKit

@Observable
@MainActor
final class AuthViewModel {

    // MARK: - Configuration Inputs

    var selectedPolicies: Set<String> = []
    var authMode: IDmeAuthMode = .oauthPKCE
    var environment: IDmeEnvironment = .production {
        didSet {
            if oldValue != environment {
                Task { await fetchPolicies() }
            }
        }
    }
    var verificationType: IDmeVerificationType = .single

    // MARK: - State

    var policies: [Policy] = []
    var credentials: Credentials?
    var payloadClaims: [(key: String, value: String)] = []
    var isLoading = false
    var isLoadingPolicies = false
    var errorMessage: String?

    var hasPayload: Bool { !payloadClaims.isEmpty }
    var isAuthenticated: Bool { credentials != nil }

    // MARK: - Credentials

    private let redirectURI = "idmedemo://idme/callback"

    private var clientId: String {
        switch environment {
        case .production: "<YOUR_PRODUCTION_CLIENT_ID>"
        case .sandbox: "<YOUR_SANDBOX_CLIENT_ID>"
        }
    }

    private var clientSecret: String {
        switch environment {
        case .production: "<YOUR_PRODUCTION_CLIENT_SECRET>"
        case .sandbox: "<YOUR_SANDBOX_CLIENT_SECRET>"
        }
    }

    // MARK: - Private

    private var idmeAuth: IDmeAuth?

    // MARK: - Policies

    func fetchPolicies() async {
        isLoadingPolicies = true

        do {
            let auth = buildAuth(scopes: [.military])
            let fetched = try await auth.policies()
            policies = fetched.filter { $0.active }
            // Clear selections that no longer exist
            let validHandles = Set(policies.map(\.handle))
            selectedPolicies = selectedPolicies.intersection(validHandles)
        } catch {
            print("[IDmeAuthDemo] fetchPolicies error: \(error)")
            policies = []
        }

        isLoadingPolicies = false
    }

    // MARK: - Actions

    func login(from window: UIWindow) async {
        isLoading = true
        errorMessage = nil
        credentials = nil
        payloadClaims = []

        do {
            let scopes = selectedPolicies.compactMap { IDmeScope(rawValue: $0) }
            let auth = buildAuth(scopes: scopes)
            idmeAuth = auth
            let creds = try await auth.login(from: window)
            credentials = creds
        } catch let error as IDmeAuthError where error == .userCancelled {
            // User dismissed — not an error to display
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshCredentials() async {
        guard let auth = idmeAuth else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            credentials = try await auth.credentials(minTTL: 0)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchPayload() async {
        guard let auth = idmeAuth else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            payloadClaims = try await auth.rawPayload()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        idmeAuth?.logout()
        idmeAuth = nil
        credentials = nil
        payloadClaims = []
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func buildAuth(scopes: [IDmeScope]) -> IDmeAuth {
        var scopes = scopes

        // OIDC mode needs the openid scope
        if authMode == .oidc && !scopes.contains(.openid) {
            scopes.insert(.openid, at: 0)
        }

        let config = IDmeConfiguration(
            clientId: clientId,
            redirectURI: redirectURI,
            scopes: scopes,
            environment: environment,
            authMode: authMode,
            verificationType: verificationType,
            clientSecret: clientSecret
        )

        return IDmeAuth(configuration: config)
    }
}
