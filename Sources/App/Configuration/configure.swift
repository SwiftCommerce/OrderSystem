import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)


    /// Register the configured MySQL database to the database config.
    let mysqlConfig = MySQLDatabaseConfig(hostname: "localhost", port: 3306, username: "root", password: "password", database: "order_system")
    
    var databases = DatabasesConfig()
    databases.add(database: MySQLDatabase(config: mysqlConfig), as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(migration: Item.self, database: .mysql)
    migrations.add(migration: Order.self, database: .mysql)
    migrations.add(migration: OrderItem.self, database: .mysql)
    migrations.add(migration: Order.Payment.self, database: .mysql)
    migrations.add(migration: AccountSetting.self, database: .mysql)
    services.register(migrations)

}
