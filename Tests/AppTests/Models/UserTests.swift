import XCTest
import JWTVapor
@testable import App

final class UserTests: XCTestCase {
    func testExpireClaimFail()throws {
        let iat = Date(timeInterval: -3600, since: Date()).timeIntervalSince1970
        let exp = Date().timeIntervalSince1970
        let user = User(exp: exp, iat: iat, email: "guest@example.com", id: -1, status: .admin)
        
        do {
            try user.verify(using: JWTSigner.hs256(key: "weak-key"))
            XCTFail("User verification should have failed")
        } catch { /* Success */ }
    }
    
    static let allTests: [(String, (UserTests) -> ()throws -> ())] = [
        ("testExpireClaimFail", testExpireClaimFail)
    ]
}
