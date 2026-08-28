import Foundation

/// Household invite code generator. Ports `src/utils/household.ts`:
/// 6 characters from A–Z and 0–9.
enum InviteCode {
    private static let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

    static func generate(length: Int = 6) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }
}
