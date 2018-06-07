import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    router.get(any, "orders", "health") { (request) in
        return "All Good!"
    }
    try router.register(collection: VersionedCollection())
}
