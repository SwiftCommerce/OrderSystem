import Service

final class GlobalConfig: ServiceType {
    static func makeService(for worker: Container) throws -> GlobalConfig {
        return GlobalConfig()
    }
    
    let guestCheckout: Bool = true
    let productService: String? = nil
    
    let paypalPayeeEmail: String? = nil
    let paypalRedirectApprove: String? = nil
    let paypalRedirectCancel: String? = nil
}
