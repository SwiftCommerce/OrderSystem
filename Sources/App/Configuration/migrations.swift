import FluentMySQL

func migrations(config: inout MigrationConfig)throws {
    config.add(model: Order.self, database: .mysql)
    config.add(model: Item.self, database: .mysql)
    config.add(model: OrderAddress.self, database: .mysql)
    config.add(model: Order.Payment.self, database: .mysql)
    config.add(model: Account.self, database: .mysql)
    config.add(model: AccountSetting.self, database: .mysql)
}
