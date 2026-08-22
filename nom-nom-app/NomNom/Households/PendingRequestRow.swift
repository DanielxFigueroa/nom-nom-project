import SwiftUI

/// Row component for a pending membership request.
/// Displays user info, checkbox for batch selection, and accept/decline action buttons.
struct PendingRequestRow: View {
    let member: HouseholdMember
    let isSelected: Bool
    let currentUserID: UUID?
    let currentUserEmail: String?
    let onToggleSelect: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .nnTint : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName(currentUserID: currentUserID, currentUserEmail: currentUserEmail))
                    .font(.body)
                    .fontWeight(.medium)

                Text("Requested to join")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.small)

                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDecline) {
                Label("Decline", systemImage: "xmark")
            }
            .tint(.red)
        }
    }
}
