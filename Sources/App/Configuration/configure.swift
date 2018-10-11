import JWTMiddleware
import FluentMySQL
import Transaction
import Vapor
import Stripe

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(TransactionProvider())
    try services.register(JWTProvider { n, _ in
        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"])
        return try RSAService(n: n, e: "AQAB", header: headers)
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
    try services.register(StorageProvider())
    
    let config = StripeConfig(productionKey: Environment.get("STRIPE_KEY") ?? "", testKey: Environment.get("STRIPE_TEST_KEY") ?? "")
    
    services.register(config)
    
    try services.register(StripeProvider())


    /// Register the configured MySQL database to the database config.
    let mysqlConfig = MySQLDatabaseConfig.init(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database:  Environment.get("DATABASE_DB") ?? "order_system"
    )
    
    var databases = DatabasesConfig()
    databases.add(database: MySQLDatabase(config: mysqlConfig), as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Order.self, database: .mysql)
    migrations.add(model: Item.self, database: .mysql)
    migrations.add(model: Order.Payment.self, database: .mysql)
    migrations.add(model: Account.self, database: .mysql)
    migrations.add(model: AccountSetting.self, database: .mysql)
    services.register(migrations)

    /// Configure controllers for making payments with third-party payment providers (i.e. PayPal or Stripe).
    var controllers = PaymentControllers(root: any, "orders", Order.parameter, "payment")
    controllers.add(PayPalController(structure: .separate))
    controllers.add(StripeController(structure: .mixed))
    services.register(controllers)
    
    services.register(GlobalConfig.self)
}
