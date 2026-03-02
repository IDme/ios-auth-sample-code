// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IDmeAuthSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "IDmeAuthSDK",
            targets: ["IDmeAuthSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "IDmeAuthSDK",
            path: "Sources/IDmeAuthSDK",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "IDmeAuthSDKTests",
            dependencies: [
                "IDmeAuthSDK",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/IDmeAuthSDKTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
