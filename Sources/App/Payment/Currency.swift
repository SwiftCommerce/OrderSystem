import Transaction
import Foundation
import PayPal
import Stripe

extension AmountConverter {
    func amount(for amount: Int?, as currency: Self.Currency) -> ProviderAmount? {
        return amount == nil ? nil : self.amount(for: amount!, as: currency)
    }
}

extension PayPal.Currency {
    func amount(for amount: Int?) -> Decimal? {
        return self.amount(for: amount, as: self)
    }
    
    func amount(for amount: Int) -> Decimal? {
        return self.amount(for: amount, as: self)
    }
}

extension StripeCurrency {
    func amount(for amount: Int?) -> Int? {
        return self.amount(for: amount, as: self)
    }
    
    func amount(for amount: Int) -> Int? {
        return self.amount(for: amount, as: self)
    }
}
