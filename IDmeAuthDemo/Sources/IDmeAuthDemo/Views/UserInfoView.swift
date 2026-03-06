import IDmeAuthSDK
import SwiftUI

struct UserInfoView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasPayload {
                    claimsList
                } else if viewModel.isAuthenticated {
                    ContentUnavailableView {
                        Label("No Data", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text("Pull down or tap below to fetch attributes.")
                    } actions: {
                        Button("Fetch Attributes") {
                            Task { await viewModel.fetchPayload() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView(
                        "Not Logged In",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text("Log in on the Login tab first.")
                    )
                }
            }
            .navigationTitle("Attributes")
            .refreshable {
                await viewModel.fetchPayload()
            }
        }
    }

    private var claimsList: some View {
        List {
            ForEach(Array(viewModel.payloadClaims.enumerated()), id: \.offset) { _, claim in
                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(claim.value)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
        }
    }
}
