import Foundation

struct PaymentGenerationContent: Codable {
    var currency: String
    var taxRate: Decimal
    var shipping: Int?
    var shippingDiscount: Int?
    var handling: Int?
    var insurence: Int?
    var giftWrap: Int?
}
