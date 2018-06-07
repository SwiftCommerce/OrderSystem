import JWTMiddleware
import Vapor

/// This is where the routes from the `AccountSettingController` are initialized and registered.
/// - note: The confomance to `RouteCollection`.
///   This requires a `.boot(router: Router)` method and allows you to call `router.register(collection: routeCollection)`.
final class VersionedCollection: RouteCollection {
    
    /// Conforms `V1Collection` to `RouteCollection`.
    ///
    /// Registers the routes from the `UserController`
    /// to the router with a root path of `any`.
    ///
    /// - Parameter router: The router the `UserController`
    ///   routes will be registered to.
    func boot(router: Router) throws {
        let group = router.grouped(any).grouped(JWTStorageMiddleware<User>())
        try group.register(collection: AccountSettingController())
        try group.register(collection: OrderController())
        
    }
}
