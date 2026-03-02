import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        TabView {
            LoginView()
                .tabItem {
                    Label("Login", systemImage: "person.badge.shield.checkmark")
                }

            CredentialsView()
                .tabItem {
                    Label("Token Exchange", systemImage: "key")
                }

            UserInfoView()
                .tabItem {
                    Label(payloadTabLabel, systemImage: "person.crop.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .alert("Error", isPresented: showingError) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var payloadTabLabel: String {
        viewModel.authMode == .oidc ? "UserInfo" : "Attributes"
    }

    private var showingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
