import SwiftUI

/// Reusable row component for an active household member.
/// Displays role badges (Owner / Member) and provides a removal context menu for the household owner.
struct MemberRow: View {
    let member: HouseholdMember
    let isCurrentHouseholdOwner: Bool
    let currentUserID: UUID?
    let currentUserEmail: String?
    var onTransferOwnership: (() -> Void)? = nil
    let onRemove: () -> Void

    var isOwner: Bool {
        member.role == .owner
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isOwner ? "star.fill" : "person.fill")
                .foregroundColor(isOwner ? .orange : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName(currentUserID: currentUserID, currentUserEmail: currentUserEmail))
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    if isOwner {
                        Text("Owner")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    } else {
                        Text("Member")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            if isCurrentHouseholdOwner && !isOwner {
                Menu {
                    if let onTransferOwnership {
                        Button(action: onTransferOwnership) {
                            Label("Transfer Ownership", systemImage: "arrow.left.arrow.right")
                        }
                    }

                    Button(role: .destructive, action: onRemove) {
                        Label("Remove from Household", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.body)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
