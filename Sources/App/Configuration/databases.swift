import FluentMySQL

func databases(config: inout DatabasesConfig, for env: Environment)throws {
    
    // Register the configured MySQL database to the database config.
    
    // Attempt to get the DB information from the environment variables used by Vapor Cloud.
    // If no value is found, default to the values used for local development.
    let host = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "root"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    let name = Environment.get("DATABASE_DB") ?? "order_system"
    let port = 3306
    
    let mysqlConfig = MySQLDatabaseConfig(
        hostname: host,
        port: port,
        username: username,
        password: password,
        database: name,
        transport: env.isRelease ? .cleartext : .unverifiedTLS
    )
    config.add(database: MySQLDatabase(config: mysqlConfig), as: .mysql)
}
