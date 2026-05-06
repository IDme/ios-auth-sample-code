# IDmeAuthSDK

iOS SDK for integrating [ID.me](https://id.me) community verification into your app using OAuth 2.0 Authorization Code with PKCE. Includes built-in token management, Keychain storage, and automatic token refresh.

## Requirements

- iOS 15+ / macOS 12+
- Swift 6.0+
- Xcode 16+

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/IDme/ios-auth-sample-code.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and enter the repository URL.

Then add `IDmeAuthSDK` to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["IDmeAuthSDK"]
)
```

## Integration Guide

The following steps walk you through a complete integration. Each step references the corresponding code in the demo app (`IDmeAuthDemo/`) so you can see a working example.

---

### Step 1: Register a URL Scheme

The SDK uses `ASWebAuthenticationSession` to open the ID.me login page in a system browser sheet. You need to register a custom URL scheme so iOS can route the OAuth callback back to your app.

Add a URL scheme to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

The scheme must match the scheme portion of your `redirectURI` (e.g. if your redirect URI is `yourapp://idme/callback`, the scheme is `yourapp`).

> **Demo app reference:** The demo registers `idmedemo` as its URL scheme and uses `idmedemo://idme/callback` as the redirect URI. See `IDmeAuthDemoApp.swift` for the `onOpenURL` handler.

---

### Step 2: Configure the SDK

Create an `IDmeConfiguration` with your client credentials and desired scopes, then initialize `IDmeAuth`:

```swift
import IDmeAuthSDK

let config = IDmeConfiguration(
    clientId: "YOUR_CLIENT_ID",
    redirectURI: "yourapp://idme/callback",
    scopes: [.military],
    clientSecret: "YOUR_CLIENT_SECRET"
)

let idme = IDmeAuth(configuration: config)
```

#### Configuration Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `clientId` | `String` | — | Your OAuth client ID from ID.me |
| `redirectURI` | `String` | — | The redirect URI registered with ID.me |
| `scopes` | `[IDmeScope]` | — | Verification scopes to request |
| `environment` | `IDmeEnvironment` | `.production` | `.production` or `.sandbox` |
| `verificationType` | `IDmeVerificationType` | `.single` | `.single` or `.groups` |
| `clientSecret` | `String?` | `nil` | Your client secret from ID.me |

#### Available Scopes

| Scope | Raw Value |
|---|---|
| `.military` | `military` |
| `.firstResponder` | `first_responder` |
| `.nurse` | `nurse` |
| `.teacher` | `teacher` |
| `.student` | `student` |
| `.governmentEmployee` | `government` |
| `.publicBenefitRecipient` | `pbr` |
| `.age` | `age` |
| `.senior` | `senior` |

#### Verification Types

| Type | Description |
|---|---|
| `.single` | Single policy — directs to `/oauth/authorize`. Use when targeting one verification community. |
| `.groups` | Multiple policies — directs to `groups.id.me`. User selects their community. **Production only.** |

> **Demo app reference:** See `AuthViewModel.swift` — the `buildAuth(scopes:)` method at line 157 shows how the configuration is assembled from user selections.

---

### Step 3: Start the Login Flow

Present the ID.me authentication sheet by passing a `UIWindow` reference. The SDK handles the full OAuth + PKCE flow — building the authorization URL, opening the browser, receiving the callback, and exchanging the code for tokens:

```swift
let credentials = try await idme.login(from: window)

print(credentials.accessToken)
print(credentials.refreshToken)
print(credentials.expiresAt)
```

The user will see the ID.me login/verification page in a system browser sheet. After completing verification, they are redirected back to your app automatically.

Handle the common error case where the user dismisses the sheet:

```swift
do {
    let credentials = try await idme.login(from: window)
} catch let error as IDmeAuthError where error == .userCancelled {
    // User dismissed the auth sheet — not an error
} catch {
    print(error.localizedDescription)
}
```

> **Demo app reference:** `AuthViewModel.swift` triggers login in the `login(from:)` method at line 78. `LoginView.swift` obtains the key window and calls this at line 137.

---

### Step 4: Fetch User Attributes

After authentication, retrieve the user's verified attributes from the `/api/public/v3/attributes.json` endpoint:

```swift
let response = try await idme.attributes()

// User attributes (e.g. name, email, UUID)
for attr in response.attributes {
    print("\(attr.handle): \(attr.value ?? "")")
}

// Verification statuses (e.g. military: verified)
for status in response.status {
    print("\(status.group): verified=\(status.verified)")
    if let subgroups = status.subgroups {
        print("  subgroups: \(subgroups.joined(separator: ", "))")
    }
}
```

The endpoint returns a JWT. The SDK decodes it automatically and returns a structured `AttributeResponse` with `attributes` and `status` arrays.

If you prefer the raw JWT payload as flat key-value pairs:

```swift
let claims = try await idme.rawPayload()
for (key, value) in claims {
    print("\(key): \(value)")
}
```

> **Demo app reference:** `AuthViewModel.swift` fetches and displays attributes in `fetchPayload()` at line 117. The `UserInfoView.swift` renders each attribute as a labeled row.

---

### Step 5: Manage Tokens

The SDK automatically stores credentials in the Keychain. Use `credentials(minTTL:)` to get valid tokens, with automatic refresh if they are about to expire:

```swift
// Get valid credentials — refreshes automatically if expiring within 60s
let creds = try await idme.credentials(minTTL: 60)

// Check expiry manually
if creds.isExpired {
    // Token has expired
}

if creds.expiresWithin(seconds: 300) {
    // Token expires within 5 minutes
}
```

> **Demo app reference:** `AuthViewModel.swift` demonstrates manual refresh in `refreshCredentials()` at line 99. The `CredentialsView.swift` displays token values, expiry status, and a refresh button.

---

### Step 6: Logout

Clear all stored credentials and tokens:

```swift
idme.logout()
```

This removes tokens from the Keychain. The user will need to verify again on next login.

> **Demo app reference:** `AuthViewModel.swift` handles logout in `logout()` at line 147, which also resets the local UI state. The `SettingsView.swift` provides a logout button with a confirmation dialog.

---

## Error Handling

All errors are thrown as `IDmeAuthError`, which conforms to `LocalizedError`:

```swift
do {
    let creds = try await idme.login(from: window)
} catch let error as IDmeAuthError {
    switch error {
    case .userCancelled:
        // User dismissed the auth sheet
        break
    case .tokenExchangeFailed(let statusCode, let message):
        print("Token exchange failed (\(statusCode)): \(message)")
    case .notAuthenticated:
        print("No credentials available")
    case .refreshTokenExpired:
        print("Session expired — user must log in again")
    default:
        print(error.localizedDescription)
    }
}
```

> **Demo app reference:** `AuthViewModel.swift` catches `IDmeAuthError.userCancelled` silently (line 90) and displays all other errors via `errorMessage`. The `ContentView.swift` shows errors in an alert dialog.

## Architecture

- **`IDmeAuth`** — Main facade (`@MainActor`). Manages the full auth lifecycle.
- **`TokenManager`** — Actor-based thread-safe token storage and refresh.
- **`CredentialStore`** — Keychain-backed credential persistence using `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **Protocol-based DI** — All network, storage, and auth session dependencies are protocol-based for testability.

## Demo App

The `IDmeAuthDemo/` directory contains a full SwiftUI app that demonstrates every SDK feature end to end:

- OAuth 2.0 + PKCE authentication
- Single and multi-policy (groups) verification
- Policy-based scope selection
- Token display, refresh, and expiry monitoring
- User attribute retrieval
- Environment switching (production/sandbox)

### Running the Demo

1. Open `IDmeAuthDemo/Package.swift` in Xcode
2. Select an iOS 17+ simulator
3. Build and run (Cmd+R)
4. Select verification policies and tap "Authenticate"

> The demo uses pre-configured ID.me test credentials. To use your own, update `clientId`, `clientSecret`, and `redirectURI` in `AuthViewModel.swift`.

## License

Copyright (c) 2025 ID.me, Inc. All rights reserved.
