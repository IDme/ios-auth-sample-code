import IDmeAuthSDK
import SwiftUI
import UIKit

struct LoginView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isAuthenticated {
                    authenticatedSection
                } else {
                    loginSection
                    policySection
                }
            }
            .navigationTitle("ID.me SDK Demo")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .task {
                if viewModel.policies.isEmpty {
                    await viewModel.fetchPolicies()
                }
            }
        }
    }

    // MARK: - Sections

    private var policySection: some View {
        Section {
            if viewModel.isLoadingPolicies {
                HStack {
                    ProgressView()
                    Text("Loading policies...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.policies.isEmpty {
                Text("No policies available. Check your credentials.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.policies) { policy in
                    policyToggle(policy)
                }
            }
        } header: {
            Text("Verification Policies")
        } footer: {
            if !viewModel.policies.isEmpty {
                Text("Select a policy to use as the OAuth scope.")
            }
        }
    }

    private var loginSection: some View {
        Section {
            Button {
                loginWithType(.single)
            } label: {
                Label("Authenticate (Single Policy)", systemImage: "person.badge.shield.checkmark")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(viewModel.selectedPolicies.isEmpty)

            if viewModel.environment == .production {
                Button {
                    loginWithType(.groups)
                } label: {
                    Label("Authenticate (Multiple Policies)", systemImage: "person.3")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(viewModel.selectedPolicies.count <= 1)
            }
        } footer: {
            if viewModel.environment == .production {
                Text("Groups verification lets the user select their community from a single page.")
            }
        }
    }

    private var authenticatedSection: some View {
        Section {
            Label("Authenticated", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)

            Text("View your credentials and user info in the other tabs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Verifying with ID.me...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func policyToggle(_ policy: Policy) -> some View {
        Toggle(isOn: Binding(
            get: { viewModel.selectedPolicies.contains(policy.handle) },
            set: { isOn in
                if isOn {
                    viewModel.selectedPolicies.insert(policy.handle)
                } else {
                    viewModel.selectedPolicies.remove(policy.handle)
                }
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text(policy.name)
                if !policy.groups.isEmpty {
                    Text(policy.groups.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func loginWithType(_ type: IDmeVerificationType) {
        viewModel.verificationType = type
        guard let window = keyWindow else { return }
        Task {
            await viewModel.login(from: window)
        }
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
