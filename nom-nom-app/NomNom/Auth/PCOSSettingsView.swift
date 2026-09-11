import SwiftUI

/// View containing the PCOS Recipe Assistant master toggle and personalized settings.
public struct PCOSSettingsView: View {
    @Environment(AuthModel.self) private var auth
    @Bindable var store: PCOSSettingsStore = .shared

    private var currentUserID: UUID? {
        auth.user?.id
    }

    public init(store: PCOSSettingsStore = .shared) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Master Toggle Row
            Toggle(isOn: Binding(
                get: { store.settings.isEnabled },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        store.setEnabled(newValue, userID: currentUserID)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.nnTint)
                        Text("PCOS Recipe Assistant")
                            .font(.body.weight(.medium))
                    }
                    Text("Tailor recipe suggestions and adjustments for PCOS nutrition")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.nnTint)

            // Preferences (revealed when enabled)
            if store.settings.isEnabled {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    // Focus Areas Subsection
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Personalized Focus Areas")
                                .font(.subheadline.weight(.semibold))
                            Text("Select priorities for AI nutritional guidance:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(PCOSFocusArea.allCases) { area in
                                focusAreaChip(area)
                            }
                        }
                    }

                    Divider()

                    // Suggestion Style Subsection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestion Style")
                            .font(.subheadline.weight(.semibold))

                        Picker("Suggestion Style", selection: Binding(
                            get: { store.settings.suggestionStyle },
                            set: { newStyle in
                                store.setSuggestionStyle(newStyle, userID: currentUserID)
                            }
                        )) {
                            ForEach(PCOSSuggestionStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(store.settings.suggestionStyle.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    private func focusAreaChip(_ area: PCOSFocusArea) -> some View {
        let isSelected = store.settings.focusAreas.contains(area)
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                store.toggleFocusArea(area, userID: currentUserID)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: area.iconName)
                    .font(.caption.weight(.semibold))
                Text(area.displayName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.nnTint : Color(.secondarySystemBackground),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(area.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}
