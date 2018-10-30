import Service

struct ProductManager: ServiceType {
    static func makeService(for worker: Container) throws -> ProductManager {
        return ProductManager(container: worker)
    }
    
    let container: Container
    let uri: String = "http://localhost:8001/v1/products"
    
    func product(for id: Item.ProductID) -> Future<Product> {
        do {
            return try self.container.client().get(uri + "/" + String(describing: id)).flatMap { response in
                return try response.content.decode(Product.self)
            }
        } catch let error {
            return self.container.future(error: error)
        }
    }
}

extension Container {
    func product(for id: Item.ProductID) -> Future<Product> {
        do {
            return try self.make(ProductManager.self).product(for: id)
        } catch let error {
            return self.future(error: error)
        }
    }
}
