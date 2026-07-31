import Foundation

extension String {
    /// Whitespace/newline-trimmed copy.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// nil when empty, otherwise self. Useful for optional DB columns.
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
