import FluentMySQL
import Vapor

struct Address: Content {
    typealias ID = Int
    
    var id: Int?
    var buildingName: String?
    var typeIdentifier: String?
    var type: String?
    var municipality: String?
    var city: String?
    var district: String?
    var postalArea: String?
    var country: String?
    var street: Street?
    
    var line1: String? {
        return nil
    }
    
    var line2: String? {
        return nil
    }
    
    static func get(for order: Order.ID, purpose: OrderAddress.Purpose, on container: Container) -> EventLoopFuture<Address?> {
        return container.databaseConnection(to: .mysql).flatMap { conn -> EventLoopFuture<OrderAddress?> in
            return OrderAddress.query(on: conn).filter(\.order == order).filter(\.purpose == purpose).first()
        }.flatMap { pivot in
            guard let addressID = pivot?.address else {
                return container.future(nil)
            }
            
            do {
                return try container.make(AddressRepository.self).get(address: addressID)
            } catch let error {
                return container.future(error: error)
            }
        }
    }
}

struct Street: Content {
    var id: Int?
    var number: Int?
    var numberSuffix: String?
    var name: String?
    var type: String?
    var direction: Direction?
}

enum Direction: String, CaseIterable, Content {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    case northEast = "NE"
    case northWest = "NW"
    case southEast = "SE"
    case southWest = "SW"
}
