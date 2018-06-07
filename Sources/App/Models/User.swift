import Foundation
import JWT
import JWTMiddleware

/// A representation of the payload used in the access tokens
/// for this service's authentication.
struct User: IdentifiableJWTPayload {
    let exp: TimeInterval
    let iat: TimeInterval
    
    // These two are to be customized according to what is in the JWT
    let email: String
    let id: Int
    
    
    func verify() throws {
        let expiration = Date(timeIntervalSince1970: self.exp)
        try ExpirationClaim(value: expiration).verify()
    }
}
