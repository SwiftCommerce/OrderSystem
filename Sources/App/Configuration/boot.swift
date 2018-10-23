import JWTVapor
import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
    
    // If in a development environment, create and log a JWT token to use for testing the service with.
    if !app.environment.isRelease && app.environment != Environment.testing {
        let signer = try app.make(JWTService.self)
        
        let now = Date().timeIntervalSince1970
        let token = User(exp: now + 3_600, iat: now, email: "token@example.com", id: Int.random(in: 0...Int.max))
        let jwt = try signer.sign(token)
        
        print("Auth Token:", jwt)
    }
}
