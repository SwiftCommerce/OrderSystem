// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "OrderSystem",
    dependencies: [
        .package(url: "https://github.com/skelpo/Transaction.git", from: "0.5.0"),
        .package(url: "https://github.com/skelpo/TransactionStripe.git", from: "0.2.0"),
        .package(url: "https://github.com/skelpo/TransactionPayPal.git", from: "0.1.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0"),
        .package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.6.1"),
        .package(url: "https://github.com/vapor-community/stripe-provider.git", from: "2.2.0")
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentMySQL",
            "JWTMiddleware",
            "Stripe",
            "Transaction",
            "TransactionStripe",
            "TransactionPayPal"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
