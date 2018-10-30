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
}
