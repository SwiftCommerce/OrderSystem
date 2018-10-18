infix operator +

protocol Combinable {
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Int: Combinable { }
extension Int8: Combinable { }
extension Int16: Combinable { }
extension Int32: Combinable { }
extension Int64: Combinable { }
extension UInt: Combinable { }
extension UInt8: Combinable { }
extension UInt16: Combinable { }
extension UInt32: Combinable { }
extension UInt64: Combinable { }
extension Float: Combinable { }
extension Double: Combinable { }
extension String: Combinable { }
extension Array: Combinable { }

extension Optional: Combinable where Wrapped: Combinable {
    static func + (lhs: Optional<Wrapped>, rhs: Optional<Wrapped>) -> Optional<Wrapped> {
        switch (lhs, rhs) {
        case let (.some(l), .some(r)): return .some(l + r)
        case let (.some(l), .none): return .some(l)
        case let (.none, .some(r)): return .some(r)
        case (.none, .none): return .none
        }
    }
    
    static func + (lhs: Wrapped, rhs: Optional<Wrapped>) -> Optional<Wrapped> {
        return Optional.some(lhs) + rhs
    }
    
    static func + (lhs: Optional<Wrapped>, rhs: Wrapped) -> Optional<Wrapped> {
        return lhs + Optional.some(rhs)
    }
}
