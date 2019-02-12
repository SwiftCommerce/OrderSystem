import Service

final class OrderService: ServiceType {
    static func makeService(for worker: Container) throws -> OrderService {
        return OrderService()
    }
    
    let guestCheckout: Bool = true
    let productService: String = Environment.get("PRODUCT_API") ?? "http://localhost:8080/v1/products"
    
    let paypalPayeeEmail: String? = Environment.get("PAYPAL_EMAIL") ?? "dispute@skelpo.com"
    let paypalRedirectApprove: String? = Environment.get("PAYPAL_REDIRECT_APPROVE") ?? "http://localhost:8081/#/order?loading=true"
    let paypalRedirectCancel: String? = Environment.get("PAYPAL_REDIRECT_CANCEL") ?? "http://localhost:8081/#/order?error=true"
    
    /// The ID of the address where the orders will be shipped from.
    /// This is used for calculating taxes using TaxJar if you have it integrated.
    ///
    /// The order ID of the address can be any value that will never match an actual
    /// order. If you are usiung `Int`, a negative value could do the trick.
    let merchantAddress: Address.ID? = nil
}
