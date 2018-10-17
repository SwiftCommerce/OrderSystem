import JWTMiddleware
import FluentMySQL
import Transaction
import Vapor

import Stripe
import PayPal

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Vapor.Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(TransactionProvider())
    try services.register(StripeProvider())
    try services.register(PayPalProvider())
    try services.register(JWTProvider { n, d in
        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"])
        return try RSAService(n: n, e: "AQAB", d: d, header: headers)
    })

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    services.register(OrderService())

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(CORSMiddleware(configuration: .default()))
    services.register(middlewares)
    
    let stripe = StripeConfig(productionKey: Environment.get("STRIPE_KEY") ?? "", testKey: Environment.get("STRIPE_TEST_KEY") ?? "")
    services.register(stripe)


    var databaseConfig = DatabasesConfig()
    try databases(config: &databaseConfig)
    services.register(databaseConfig)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Order.self, database: .mysql)
    migrations.add(model: Item.self, database: .mysql)
    migrations.add(model: Address.self, database: .mysql)
    migrations.add(model: Order.Payment.self, database: .mysql)
    migrations.add(model: Account.self, database: .mysql)
    migrations.add(model: AccountSetting.self, database: .mysql)
    services.register(migrations)

    /// Configure controllers for making payments with third-party payment providers (i.e. PayPal or Stripe).
    var controllers = PaymentControllers(root: any, "orders")
    controllers.add(PayPalController(structure: .separate))
    controllers.add(StripeController(structure: .mixed))
    services.register(controllers)
    
    services.register(GlobalConfig.self)
    services.register(Storage())
}
