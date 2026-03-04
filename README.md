# IDmeAuthSDK

A native iOS SDK for integrating [ID.me](https://id.me) identity verification into your app. Supports OAuth 2.0 + PKCE and OpenID Connect (OIDC) flows with built-in token management, Keychain storage, and JWT validation.

## Requirements

- iOS 15+ / macOS 12+
- Swift 5.9+
- Xcode 15+

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

## Quick Start

### 1. Configure the SDK

```swift
import IDmeAuthSDK

let config = IDmeConfiguration(
    clientId: "YOUR_CLIENT_ID",
    redirectURI: "yourapp://idme/callback",
    scopes: [.military],
    environment: .production,
    authMode: .oauthPKCE,
    clientSecret: "YOUR_CLIENT_SECRET"
)

let idme = IDmeAuth(configuration: config)
```

### 2. Register Your URL Scheme

In your app's `Info.plist`, register the redirect URI scheme:

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

### 3. Start the Login Flow

```swift
// From a UIKit context
let credentials = try await idme.login(from: window)

// Access tokens
print(credentials.accessToken)
print(credentials.refreshToken)
print(credentials.expiresAt)
```

### 4. Retrieve User Info

```swift
// OIDC — returns structured UserInfo
let userInfo = try await idme.userInfo()
print(userInfo.email)

// OAuth — returns attributes and verification statuses
let attributes = try await idme.attributes()
for attr in attributes.attributes {
    print("\(attr.handle): \(attr.value)")
}

// Raw JWT payload as key-value pairs
let claims = try await idme.rawPayload()
for (key, value) in claims {
    print("\(key): \(value)")
}
```

### 5. Token Management

The SDK automatically stores credentials in the Keychain and provides token refresh:

```swift
// Get valid credentials, refreshing if needed
let creds = try await idme.credentials(minTTL: 60)

// Check expiry
if creds.isExpired {
    // Token has expired
}

if creds.expiresWithin(seconds: 300) {
    // Token expires within 5 minutes
}
```

### 6. Fetch Available Policies

Discover which verification policies your organization supports:

```swift
let policies = try await idme.policies()
for policy in policies where policy.active {
    print("\(policy.name) — scope: \(policy.handle)")
}
```

### 7. Logout

```swift
idme.logout()
```

## Configuration Reference

### `IDmeConfiguration`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `clientId` | `String` | — | OAuth client ID from ID.me |
| `redirectURI` | `String` | — | Registered redirect URI |
| `scopes` | `[IDmeScope]` | — | Verification scopes to request |
| `environment` | `IDmeEnvironment` | `.production` | `.production` or `.sandbox` |
| `authMode` | `IDmeAuthMode` | `.oauthPKCE` | `.oauth`, `.oauthPKCE`, or `.oidc` |
| `verificationType` | `IDmeVerificationType` | `.single` | `.single` or `.groups` |
| `clientSecret` | `String?` | `nil` | Required for `.oauth` mode |

### Auth Modes

| Mode | Description |
|---|---|
| `.oauthPKCE` | **Recommended.** OAuth 2.0 Authorization Code with PKCE. No client secret sent to authorize endpoint. |
| `.oauth` | Standard OAuth 2.0 Authorization Code. Requires `clientSecret`. |
| `.oidc` | OpenID Connect. Returns an ID token with JWT signature validation against ID.me's JWKS. |

### Verification Types

| Type | Description |
|---|---|
| `.single` | Single policy — directs to `/oauth/authorize`. Use for a single verification community. |
| `.groups` | Multiple policies — directs to `groups.id.me`. User selects their community. **Production only.** |

### Scopes

| Scope | Raw Value |
|---|---|
| `.openid` | `openid` |
| `.profile` | `profile` |
| `.email` | `email` |
| `.military` | `military` |
| `.firstResponder` | `first_responder` |
| `.nurse` | `nurse` |
| `.teacher` | `teacher` |
| `.student` | `student` |
| `.governmentEmployee` | `government` |
| `.lowIncome` | `low_income` |

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
    default:
        print(error.localizedDescription)
    }
}
```

## Architecture

- **`IDmeAuth`** — Main facade (`@MainActor`). Manages the full auth lifecycle.
- **`TokenManager`** — Actor-based thread-safe token storage and refresh.
- **`CredentialStore`** — Keychain-backed credential persistence using `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **`JWTValidator`** — RS256 signature verification against ID.me's JWKS endpoint (OIDC mode).
- **Protocol-based DI** — All network, storage, and auth session dependencies are protocol-based for testability.

## Demo App

The `IDmeAuthDemo/` directory contains a full SwiftUI demo app that showcases all SDK features:

- OAuth + PKCE and OIDC authentication flows
- Single and multi-policy (groups) verification
- Dynamic policy discovery from the `/api/public/v3/policies` endpoint
- Token display, refresh, and expiry monitoring
- Raw JWT payload inspection
- Environment switching (production/sandbox)

### Running the Demo

1. Open `IDmeAuthDemo/Package.swift` in Xcode
2. Select an iOS 17+ simulator
3. Build and run (Cmd+R)
4. Select verification policies and tap "Authenticate"

> The demo uses pre-configured ID.me test credentials. To use your own, update the `clientId`, `clientSecret`, and `redirectURI` in `AuthViewModel.swift`.

## License

Copyright (c) 2025 ID.me, Inc. All rights reserved.
