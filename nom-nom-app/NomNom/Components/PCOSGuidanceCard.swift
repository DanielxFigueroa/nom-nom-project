import SwiftUI

/// A tinted, left-bordered card used for the PCOS guidance section (SPEC.md §4).
struct PCOSGuidanceCard: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.nnTint)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.nnTint)
            }
            Text(text)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.nnTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.nnTint)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}
