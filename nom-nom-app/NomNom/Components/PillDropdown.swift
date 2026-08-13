import SwiftUI

/// A reusable pill-shaped control matching the Collectr reference design.
/// Displays a leading SF symbol, label text, and trailing chevron.
struct PillDropdown: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isActive
                ? Color.nnTint
                : Color(.secondarySystemBackground)
            )
            .foregroundColor(isActive ? .white : .primary)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
