/// Every payment provider has to adjust to this protocol.
///

import Vapor

struct PaymentMethodReturn: Content {
    var success: Bool = true
    var message: String = ""
    var redirectUrl: String?
    var data: String?
    var transactionId: Int?
}


protocol PaymentMethod {
    /// Can this payment method take time, like a few minutes or hours until it is finished?
    static var pendingPossible: Bool { get }
    /// Is pre-authentification needed? Like when charging a credit card?
    /// Note: This may be "chosen" and not obgligated. The final charge may be wanted a little later.
    static var preauthNeeded: Bool { get }
    /// The name of this payment method.
    static var name: String { get }
    static var slug: String { get }
    
    /// Initializes the payment method with credentials.
    init(request: Request)
    
    /// Is called periodically to update pending transactions.
    func workThroughPendingTransactions()
    
    /// creates a new transaction, this function is used internally
    func createTransaction(orderId: Order.ID, userId: Int, amount: Int?, status: Order.PaymentStatus?) -> Future<Order.Payment>
    
    /// pays for an order, this function is initiated by the user.
    func payForOrder(order: Order, userId: Int, amount: Int, params: Any?) throws -> Future<PaymentMethodReturn>
    
    ///
    func refundTransaction(payment: Order.Payment, amount: Int?) -> Future<Order.Payment>
    
}
