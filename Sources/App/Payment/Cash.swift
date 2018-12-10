import Transaction
import Vapor

typealias CashController = PaymentController<CashPayment>
extension VoidCodable: Content {}

struct CashPayment: PaymentMethod {
    typealias Purchase = Order
    typealias Payment = Order.Payment
    typealias ExecutionData = VoidCodable
    
    static var name: String = "Cash Payment"
    static var slug: String = "cash"
    
    var container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    func payment(for purchase: Order, with content: PaymentGenerationContent) -> EventLoopFuture<Order.Payment> {
        return purchase.payment(on: self.container, with: self, content: content, externalID: Optional<String>.none)
    }
    
    func execute(payment: Order.Payment, with data: VoidCodable) -> EventLoopFuture<Order.Payment> {
        return self.container.future(payment)
    }
    
    func refund(payment: Order.Payment, amount: Int?) -> EventLoopFuture<Order.Payment> {
        if let refund = amount {
            payment.refunded += refund
            return self.container.databaseConnection(to: .mysql).flatMap { connection in
                return payment.update(on: connection)
            }
        }
        
        return self.container.future(payment)
    }
}

extension CashPayment: CreatedPaymentResponse {
    func created(from payment: Order.Payment) -> EventLoopFuture<Order.Payment> {
        return self.container.future(payment)
    }
}

extension CashPayment: ExecutedPaymentResponse {
    func executed(from payment: Order.Payment) -> EventLoopFuture<Order.Payment> {
        return self.container.future(payment)
    }
}
