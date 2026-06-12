import Foundation

enum DecimalInput {
    /// Parses a user-entered decimal string into a `Decimal`.
    ///
    /// Tries the user's current locale first (so "1 234,56" parses on fr_FR
    /// and "1,234.56" parses on en_US, grouping separators included). Falls
    /// back to permissive parsing that accepts either '.' or ',' as the
    /// decimal separator, for input pasted from a different locale.
    /// Returns `nil` for empty/whitespace-only or unparseable input.
    static func parse(_ string: String) -> Decimal? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: trimmed) {
            return number.decimalValue
        }

        return Decimal(string: trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
