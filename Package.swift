// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "OrderSystem",
    dependencies: [
        .package(url: "https://github.com/skelpo/Transaction.git", from: "0.2.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.6.1"),
        .package(url: "https://github.com/vapor-community/stripe-provider.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentMySQL", "JWTMiddleware", "Stripe", "Transaction"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
