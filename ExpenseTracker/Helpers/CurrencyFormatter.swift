import Foundation

enum CurrencyFormatter {
    static func string(from amount: Decimal, locale: Locale = .current) -> String {
        amount.formatted(.currency(code: locale.currency?.identifier ?? "USD").locale(locale))
    }

    static func string(from amount: Double, locale: Locale = .current) -> String {
        string(from: Decimal(amount), locale: locale)
    }

    static var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
}
