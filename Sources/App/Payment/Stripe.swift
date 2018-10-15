import TransactionStripe
import Stripe

typealias StripeCC = StripeCreditCard<Order, Order.Payment>
typealias StripeController = PaymentController<StripeCC>

extension Order.Payment: PaymentStructure {}
