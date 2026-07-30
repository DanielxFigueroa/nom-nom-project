import SwiftUI

/// Palette mirrored from the RN app's `constants/theme.ts`.
extension Color {
    static let nnTint = Color(hex: 0x0A7EA4)     // primary / tint
    static let nnSuccess = Color(hex: 0x34C759)  // create / join
    static let nnError = Color(hex: 0xE53E3E)    // delete / danger
    static let nnSplash = Color(hex: 0x208AEF)   // splash background

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
