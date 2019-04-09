// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "OrderSystem",
    dependencies: [
        .package(url: "https://github.com/skelpo/ModelResponse.git", from: "0.1.0"),
        .package(url: "https://github.com/skelpo/TaxCalculator.git", from: "0.1.0"),
        .package(url: "https://github.com/skelpo/Transaction.git", from: "0.6.1"),
        .package(url: "https://github.com/skelpo/TransactionStripe.git", from: "0.2.1"),
        .package(url: "https://github.com/skelpo/TransactionPayPal.git", from: "0.2.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.1"),
        .package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.9.0"),
        .package(url: "https://github.com/vapor-community/stripe-provider.git", from: "2.3.2")
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentMySQL",
            "JWTMiddleware",
            "Stripe",
            "Transaction",
            "TransactionStripe",
            "TransactionPayPal",
            "TaxCalculator",
            "ModelResponse"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
