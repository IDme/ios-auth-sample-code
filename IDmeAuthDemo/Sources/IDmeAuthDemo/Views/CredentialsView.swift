import IDmeAuthSDK
import SwiftUI
import UIKit

struct CredentialsView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if let creds = viewModel.credentials {
                    credentialsList(creds)
                } else {
                    ContentUnavailableView(
                        "No Credentials",
                        systemImage: "key.slash",
                        description: Text("Log in on the Login tab to view your credentials.")
                    )
                }
            }
            .navigationTitle("Token Exchange")
        }
    }

    // MARK: - Credentials List

    private func credentialsList(_ creds: Credentials) -> some View {
        List {
            Section("Access Token") {
                TokenRow(label: "Token", value: creds.accessToken)
            }

            if let refresh = creds.refreshToken {
                Section("Refresh Token") {
                    TokenRow(label: "Token", value: refresh)
                }
            }

            Section("Token Info") {
                LabeledContent("Type", value: creds.tokenType)
                expiryRow(creds)
            }

            Section {
                Button {
                    Task { await viewModel.refreshCredentials() }
                } label: {
                    Label("Refresh Now", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func expiryRow(_ creds: Credentials) -> some View {
        let remaining = creds.expiresAt.timeIntervalSince(Date())
        let color: Color = if creds.isExpired {
            .red
        } else if remaining < 300 {
            .yellow
        } else {
            .green
        }

        return LabeledContent("Expires") {
            VStack(alignment: .trailing, spacing: 2) {
                Text(creds.expiresAt, style: .relative)
                    .foregroundStyle(color)
                Text(creds.expiresAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Token Row

private struct TokenRow: View {
    let label: String
    let value: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(truncated)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIPasteboard.general.string = value
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                copied = false
            }
        }
        .overlay(alignment: .trailing) {
            if copied {
                Text("Copied!")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green, in: Capsule())
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: copied)
    }

    private var truncated: String {
        if value.count > 40 {
            return String(value.prefix(20)) + "..." + String(value.suffix(10))
        }
        return value
    }
}
