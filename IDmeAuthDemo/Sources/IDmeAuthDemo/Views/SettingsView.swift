import IDmeAuthSDK
import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @State private var showLogoutConfirmation = false

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Form {
                Section("Environment") {
                    Picker("Environment", selection: $vm.environment) {
                        Text("Production").tag(IDmeEnvironment.production)
                        Text("Sandbox").tag(IDmeEnvironment.sandbox)
                    }
                    .pickerStyle(.segmented)

                    if viewModel.environment == .sandbox {
                        Text("Uses api.idmelabs.com. Groups verification is not available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Uses api.id.me. All features available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("SDK Info") {
                    LabeledContent("SDK Version", value: IDmeAuthSDK.version)
                }

                if viewModel.isAuthenticated {
                    Section {
                        Button(role: .destructive) {
                            showLogoutConfirmation = true
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Logout", isPresented: $showLogoutConfirmation) {
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
            } message: {
                Text("This will clear all stored credentials. You'll need to verify again.")
            }
        }
    }
}
