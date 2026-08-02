import Foundation

/// Utility for formatting numeric recipe quantities into human-readable fractions or decimals.
struct FractionFormatter {
    /// Formats a numeric quantity into a clean fraction or decimal string.
    /// E.g. 1.5 -> "1 ½", 0.25 -> "¼", 4.0 -> "4", 1.333 -> "1 ⅓".
    static func format(_ value: Double) -> String {
        guard value > 0 else { return "0" }

        let whole = Int(floor(value + 0.00001))
        let frac = value - Double(whole)

        if frac < 0.015 {
            return String(whole)
        }
        if frac > 0.985 {
            return String(whole + 1)
        }

        let fracSymbol: String?
        if abs(frac - 0.25) < 0.02 {
            fracSymbol = "¼"
        } else if abs(frac - (1.0 / 3.0)) < 0.025 {
            fracSymbol = "⅓"
        } else if abs(frac - 0.5) < 0.02 {
            fracSymbol = "½"
        } else if abs(frac - (2.0 / 3.0)) < 0.025 {
            fracSymbol = "⅔"
        } else if abs(frac - 0.75) < 0.02 {
            fracSymbol = "¾"
        } else if abs(frac - 0.125) < 0.015 {
            fracSymbol = "⅛"
        } else if abs(frac - 0.375) < 0.015 {
            fracSymbol = "⅜"
        } else if abs(frac - 0.625) < 0.015 {
            fracSymbol = "⅝"
        } else if abs(frac - 0.875) < 0.015 {
            fracSymbol = "⅞"
        } else {
            fracSymbol = nil
        }

        if let fracSymbol {
            if whole > 0 {
                return "\(whole) \(fracSymbol)"
            } else {
                return fracSymbol
            }
        }

        // Fallback for non-standard decimals: format up to 2 decimal places, removing trailing zeros
        let formatted = String(format: "%.2f", value)
            .replacingOccurrences(of: "(?<=\\.\\d*?)0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        return formatted
    }
}
