import Vapor

protocol AddressRepository: ServiceType {
    func get(address: Address.ID) -> EventLoopFuture<Address?>
    func save(address: Address) -> EventLoopFuture<Address>
}

/// An `AddressRepository`implementation that interfaces with a `SwiftCommerce/AddressManager` micro-service.
final class SCAddressRepository: AddressRepository {
    static func makeService(for container: Container) throws -> SCAddressRepository {
        guard let host = Environment.get("ADDRESS_SERVICE") else {
            throw Abort(.internalServerError, reason: "Cannot get value for `ADDRESS_SERVICE` environment variable")
        }
        return try SCAddressRepository(client: container.make(), host: host)
    }
    
    let client: Client
    let host: String
    
    init(client: Client, host: String) {
        self.client = client
        self.host = host
    }
    
    func get(address: Address.ID) -> EventLoopFuture<Address?> {
        return self.client.get("\(self.host)/\(address)").flatMap { response in
            switch response.http.status {
            case .ok: break
            case .notFound: return self.client.container.future(nil)
            default: throw Abort(.failedDependency, reason: "Got status \(response.http.status) from address service")
            }
            
            return try response.content.decode(Address.self).map { $0 }
        }
    }
    
    func save(address: Address) -> EventLoopFuture<Address> {
        return self.client.post(self.host).flatMap { response in
            guard response.http.status == .ok || response.http.status == .created else {
                throw Abort(.failedDependency, reason: "Got status \(response.http.status) from address service")
            }
            
            return try response.content.decode(Address.self)
        }
    }
}
