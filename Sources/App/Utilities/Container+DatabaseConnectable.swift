import Service
import Fluent

extension Container {
    func databaseConnection<Database>(to database: DatabaseIdentifier<Database>?) -> Future<Database.Connection> {
        guard let database = database else {
            let error = FluentError(identifier: "noDatabaseID", reason: "Attempted to get database connection without a Database ID")
            return self.future(error: error)
        }
        
        do {
            return try self.connectionPool(to: database).withConnection { connection in self.future(connection) }
        } catch let error {
            return self.future(error: error)
        }
    }
}
