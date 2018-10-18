import TransactionPayPal
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Order.Payment: ExecutablePayment {
    var total: Int {
        let fees: Int? = self.shipping + self.handling + self.shippingDiscount + self.insurence + self.giftWrap
        return self.subtotal + fees ?? self.subtotal
    }
}
