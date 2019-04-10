import TaxCalculator
import JWTMiddleware
import FluentMySQL
import Transaction
import Vapor

import Stripe
import PayPal

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Vapor.Environment, _ services: inout Services) throws {
    guard let paypalID = Environment.get("PAYPAL_CLIENT_ID"), let paypalSecret = Environment.get("PAYPAL_CLIENT_SECRET") else {
        throw Abort(.internalServerError, reason: "Missing environment variable(s) `PAYPAL_CLIENT_ID` and/or `PAYPAL_CLIENT_SECRET`")
    }
    
    
    /// Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(TransactionProvider())
    try services.register(JWTProvider { n, d in
        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"])
        return try RSAService(n: n, e: "AQAB", d: d, header: headers)
    })
    
    try services.register(StripeProvider())
    try services.register(PayPalProvider(id: paypalID, secret: paypalSecret))
    services.register(factory: CashPayment.init)

    
    /// Register routes to the router
    services.register(Router.self) { container -> EngineRouter in
        let router = EngineRouter.default()
        try routes(router, container: container)
        return router
    }
    services.register(OrderService())

    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware(configuration: .default()))
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    let stripe = StripeConfig(productionKey: Environment.get("STRIPE_KEY") ?? "", testKey: Environment.get("STRIPE_TEST_KEY") ?? "")
    services.register(stripe)


    var databaseConfig = DatabasesConfig()
    try databases(config: &databaseConfig, for: env)
    services.register(databaseConfig)

    
    /// Configure migrations
    var migrationConfig = MigrationConfig()
    try migrations(config: &migrationConfig)
    services.register(migrationConfig)

    var commandConfig = CommandConfig.default()
    try commands(config: &commandConfig)
    services.register(commandConfig)
    
    /// Configure controllers for making payments with third-party payment providers (i.e. PayPal or Stripe).
    var controllers = PaymentControllers(root: any, "orders")
    controllers.middleware(JWTStorageMiddleware<User>())
    controllers.add(PayPalController(structure: .separate))
    controllers.add(StripeController(structure: .mixed))
    controllers.add(CashController(structure: .mixed))
    services.register(controllers)
    
    services.register(OrderService.self)
    
    services.register(Storage())
    services.register(PayPalPayment.self)
    services.register(StripeCC.self)
    
    services.register(factory: { (container) -> GenericTaxCalculator in
        return GenericTaxCalculator(percentage: 7.25, on: container)
    })
}
