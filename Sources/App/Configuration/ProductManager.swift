import Service

struct ProductManager: ServiceType {
    static func makeService(for worker: Container) throws -> ProductManager {
        return ProductManager(container: worker)
    }
    
    let container: Container
}
