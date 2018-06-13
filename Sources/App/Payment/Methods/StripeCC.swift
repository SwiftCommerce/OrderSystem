//
//  CashPaymentMethod.swift
//  App
//
//  Created by Ralph Küpper on 5/18/18.
//
import Vapor
import Stripe

class StripeCCPaymentMethod: PaymentMethod {
    
    var request: Request
    
    static var pendingPossible: Bool {
        return false
    }
    /// Is pre-authentification needed? Like when charging a credit card?
    /// Note: This may be "chosen" and not obgligated. The final charge may be wanted a little later.
    static var preauthNeeded: Bool {
        return false
    }
    /// The name of this payment method.
    static var name: String {
        return "Credit Card (Stripe)"
    }
    static var slug: String {
        return "stripeCC"
    }
    
    required init(request: Request) {
        self.request = request
    }
    
    /// Is called periodically to update pending transactions.
    func workThroughPendingTransactions() {
        // nothin gin here
    }
    
    /// creates a new transaction, this function is used internally
    func createTransaction(orderId: Order.ID, userId: Int, amount: Int?, status: Order.PaymentStatus?) -> Future<Order.Payment> {
        var paid = amount ?? 0
        var refunded = 0
        if status != Order.PaymentStatus.paid {
            paid = 0
            refunded = amount ?? 0
        }
        return Order.Payment(orderID: orderId, paymentMethod: StripeCCPaymentMethod.slug, paidTotal: paid, refundedTotal: refunded).save(on: self.request)
    }
    
    /// pays for an order, this function is initiated by the user.
    func payForOrder(order: Order, userId: Int, amount: Int, params: Any?) throws -> Future<PaymentMethodReturn> {
        
        let _ = try self.request.make(OrderService.self)
        let stripeClient = try self.request.make(StripeClient.self)
        
        return try stripeClient.charge.create(amount: amount, currency: .usd, description: "Order \(order.id!)", source: params).flatMap(to: PaymentMethodReturn.self){ (charge) in
            if charge.captured! && charge.amount! == amount {
                return self.createTransaction(orderId: order.id!, userId: userId, amount: charge.amount!, status: .paid).map(to: PaymentMethodReturn.self) { transaction in
                    return PaymentMethodReturn(success: true, message: "All wunderful", redirectUrl: nil, data: nil, transactionId: transaction.id)
                }
            }
            else {
                return self.request.eventLoop.newSucceededFuture(result: PaymentMethodReturn(success: false, message: "Did not go through", redirectUrl: nil, data: charge.failureMessage!, transactionId:nil))
            }
            
        }
    }
    
    ///
    func refundTransaction(payment: Order.Payment, amount: Int?) -> Future<Order.Payment> {
        return self.request.eventLoop.newSucceededFuture(result: payment)
    }
}
