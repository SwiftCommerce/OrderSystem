import Vapor

/// Register your application's routes here.
public func routes(_ router: Router, container: Container) throws {
    router.get(any, "orders", "health") { (request) in
        return "All Good!"
    }
    
    
    let base = router.grouped(any)
    try base.register(collection: AccountSettingController())
    try base.register(collection: OrderController(addresses: container.make()))
}
