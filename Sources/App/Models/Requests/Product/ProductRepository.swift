import Vapor

protocol ProductRepository: ServiceType {
    func get(product id: Item.ProductID) -> EventLoopFuture<Product?>
    func get(products ids: [Item.ProductID]) -> EventLoopFuture<[Product?]>
}

final class SCProductRepository: ProductRepository {
    static func makeService(for container: Container) throws -> SCProductRepository {
        return try SCProductRepository(client: container.make(), host: container.make(OrderService.self).productService)
    }
    
    let client: Client
    let host: String
    
    init(client: Client, host: String) {
        self.client = client
        self.host = host
    }
    
    func get(product id: Item.ProductID) -> EventLoopFuture<Product?> {
        return self.client.get("\(self.host)/\(id)").flatMap { response in
            switch response.http.status {
            case .ok: break
            case .notFound: return self.client.container.future(nil)
            default: throw Abort(.failedDependency, reason: "Got status `\(response.http.status)` from product service")
            }
            
            return try response.content.decode(Product.self).map { $0 }
        }
    }
    
    func get(products ids: [Item.ProductID]) -> EventLoopFuture<[Product?]> {
        return ids.map(self.get(product:)).flatten(on: self.client.container)
    }
}
