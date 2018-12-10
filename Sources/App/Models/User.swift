import Foundation
import JWT
import JWTMiddleware

/// A representation of the payload used in the access tokens
/// for this service's authentication.
struct User: IdentifiableJWTPayload {
    let exp: TimeInterval
    let iat: TimeInterval
    
    // These properties are to be customized according to what is in the JWT
    let email: String
    let id: Int?
    let status: Status?
    
    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: self.exp)
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}

extension User {
    enum Status: RawRepresentable, Codable, Equatable {
        case admin
        case moderator
        case standard
        case other(Int)
        
        init?(rawValue: Int) {
            switch rawValue {
            case 0: self = .admin
            case 1: self = .moderator
            case 2: self = .standard
            default: self = .other(rawValue)
            }
        }
        
        var rawValue: Int {
            switch self {
            case .admin: return 0
            case .moderator: return 1
            case .standard: return 2
            case let .other(raw): return raw
            }
        }
    }

}
