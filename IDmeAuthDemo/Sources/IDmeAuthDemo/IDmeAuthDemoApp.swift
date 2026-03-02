import SwiftUI

@main
struct IDmeAuthDemoApp: App {
    @State private var viewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .onOpenURL { url in
                    // The SDK handles the redirect internally via ASWebAuthenticationSession,
                    // but we register the scheme so iOS routes back to this app.
                }
        }
    }
}
