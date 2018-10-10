import TransactionPayPal
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Order.Payment: ExecutablePayment {
    var currency: Currency {
        return .usd
    }
    
    var total: String {
        return String(describing: self.paidTotal)
    }
}
