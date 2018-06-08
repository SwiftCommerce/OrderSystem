//
//  CashPaymentMethod.swift
//  App
//
//  Created by Ralph Küpper on 5/18/18.
//
@testable import App
import Vapor

class CashPaymentMethod: PaymentMethod {
    
    var request: Request
    
    static var pendingPossible: Bool {
        return true
    }
    /// Is pre-authentification needed? Like when charging a credit card?
    /// Note: This may be "chosen" and not obgligated. The final charge may be wanted a little later.
    static var preauthNeeded: Bool {
        return false
    }
    /// The name of this payment method.
    static var name: String {
        return "Cash"
    }
    static var slug: String {
        return "cash"
    }
    
    required init(request: Request) {
        self.request = request
    }
    
    /// Is called periodically to update pending transactions.
    func workThroughPendingTransactions() {
        // TODO
    }
    
    /// creates a new transaction, this function is used internally
    func createTransaction(orderId: Order.ID, userId: Int, amount: Int?, status: Order.PaymentStatus?) -> Future<Order.Payment> {
        var paid = amount ?? 0
        var refunded = 0
        if status != Order.PaymentStatus.paid {
            paid = 0
            refunded = amount ?? 0
        }
        return Order.Payment(orderID: orderId, paymentMethod: CashPaymentMethod.slug, paidTotal: paid, refundedTotal: refunded).save(on: self.request)
    }
    
    /// pays for an order, this function is initiated by the user.
    func payForOrder(order: Order, userId: Int, amount: Int?) -> Future<PaymentMethodReturn> {
        let ret = PaymentMethodReturn(success: true, message: "All wunderful", redirectUrl: nil, data: nil, transactionId: nil)
        return self.request.eventLoop.newSucceededFuture(result: ret)
    }
    
    ///
    func refundTransaction(payment: Order.Payment, amount: Int?) -> Future<Order.Payment> {
        return self.request.eventLoop.newSucceededFuture(result: payment)
    }
}
