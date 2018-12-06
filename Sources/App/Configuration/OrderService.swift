import Service

final class OrderService: ServiceType {
    static func makeService(for worker: Container) throws -> OrderService {
        return OrderService()
    }
    
    let guestCheckout: Bool = true
    let productService: String? = nil
    
    let paypalPayeeEmail: String? = "dispute@skelpo.com"
    let paypalRedirectApprove: String? = "http://www.skelpo.codes/PayPal"
    let paypalRedirectCancel: String? = "http://www.skelpo.codes/PayPal"
    
    /// The ID of the address where the orders will be shipped from.
    /// This is used for calculating taxes using TaxJar if you have it integrated.
    ///
    /// The order ID of the address can be any value that will never match an actual
    /// order. If you are usiung `Int`, a negative value could do the trick.
    let merchantAddress: Address.ID? = nil
}
