import TransactionPayPal
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Int {
    func formatted(for currency: CurrencyProtocol) -> String {
        let exponent: Int
        if let currency = currency as? Currency {
            exponent = currency.e ?? 0
        } else {
            exponent = 0
        }

        var string = String(describing: self)
        
        if exponent == 0 {
            return string
        }
        if string.count > exponent {
            string.insert(".", at: string.index(string.endIndex, offsetBy: -exponent))
        } else {
            return "0." + String(repeating: "0", count: exponent - string.count) + string
        }
        return string
    }
}

extension Order.Payment: ExecutablePayment {
    var total: String {
        if let paypalCurrency = PayPal.Currency(code: self.currency) {
            return self.paidTotal.formatted(for: paypalCurrency)
        } else {
            return String(describing: self.paidTotal)
        }
    }
}
