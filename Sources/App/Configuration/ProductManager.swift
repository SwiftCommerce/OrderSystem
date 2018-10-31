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
    
    func products(for ids: [Item.ProductID]) -> Future<[Product]> {
        return ids.map(self.product).flatten(on: self.container)
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
    
    func products(for ids: [Item.ProductID]) -> Future<[Product]> {
        return ids.map(self.product).flatten(on: self)
    }
    
    func products(for items: [Item]) -> Future<[(item: Item, product: Product)]> {
        return products(for: items.map { $0.productID }).map { products in
            return items.reduce(into: []) { result, item in
                if let product = products.first(where: { $0.id == item.productID }) {
                    result.append((item, product))
                }
            }
        }
    }
}
