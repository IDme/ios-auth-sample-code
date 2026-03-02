// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IDmeAuthDemo",
    platforms: [.iOS(.v17), .macOS(.v12)],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "IDmeAuthDemo",
            dependencies: [
                .product(name: "IDmeAuthSDK", package: "ios-auth-sample-code"),
            ]
        ),
    ]
)
