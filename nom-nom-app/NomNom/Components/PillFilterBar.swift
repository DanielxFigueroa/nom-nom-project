import SwiftUI

private enum FilterSheetType: String, Identifiable {
    case sort
    case tags
    case folder
    case household

    var id: String { rawValue }
}

/// Horizontal row of pill-shaped dropdown controls for Explore (Sort, Tags, Folder, Household).
/// Tapping a pill presents a custom bottom sheet matching the Collectr visual reference.
struct PillFilterBar: View {
    @Bindable var model: ExploreModel
    @State private var activeSheet: FilterSheetType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 0. Household Pill (shown when user is part of multiple households)
                if model.joinedHouseholds.count > 1 {
                    let isHouseholdActive = model.selectedHouseholdID != nil
                    let householdLabel: String = {
                        if let selectedID = model.selectedHouseholdID,
                           let house = model.joinedHouseholds.first(where: { $0.id == selectedID }) {
                            return house.name ?? "Household"
                        }
                        return "All Households"
                    }()

                    PillDropdown(
                        icon: isHouseholdActive ? "house.fill" : "house",
                        label: householdLabel,
                        isActive: isHouseholdActive
                    ) {
                        activeSheet = .household
                    }
                }

                // 1. Sort Pill
                PillDropdown(
                    icon: "arrow.up.arrow.down",
                    label: model.sort == .newest ? "Sort" : model.sort.displayName,
                    isActive: model.sort != .newest
                ) {
                    activeSheet = .sort
                }

                // 2. Tags Pill
                let selectedCount = model.selectedTagIDs.count
                let tagLabel: String = {
                    if selectedCount == 0 {
                        return "Tags"
                    } else if selectedCount == 1,
                              let tagID = model.selectedTagIDs.first,
                              let tag = model.availableTags.first(where: { $0.id == tagID }) {
                        return tag.name
                    } else {
                        return "\(selectedCount) Tags"
                    }
                }()

                PillDropdown(
                    icon: "tag",
                    label: tagLabel,
                    isActive: selectedCount > 0
                ) {
                    activeSheet = .tags
                }

                // 3. Folder Pill
                let isFolderActive = model.selectedFolderID != nil
                let folderLabel = model.selectedFolder?.name ?? "Folder"

                PillDropdown(
                    icon: isFolderActive ? "folder.fill" : "folder",
                    label: folderLabel,
                    isActive: isFolderActive
                ) {
                    activeSheet = .folder
                }

                // 4. Reset Button (shown when any filter is active)
                if model.hasActiveFilters {
                    Button {
                        model.clearFilters()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Reset")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(.tertiarySystemBackground))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sort:
                SortFilterSheet(model: model)
            case .tags:
                TagsFilterSheet(model: model)
            case .folder:
                FolderFilterSheet(model: model)
            case .household:
                HouseholdFilterSheet(model: model)
            }
        }
    }
}

// MARK: - Reusable Sheet Layout Container

private struct FilterSheetContainer<Content: View>: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            // Content List
            ScrollView {
                VStack(spacing: 12) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Reusable Card Option Row

private struct FilterOptionCard: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var isPCOS: Bool = false
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if isPCOS {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .foregroundColor(.nnTint)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(isSelected ? .nnTint : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundColor(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.nnTint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Filter Sheet

private struct SortFilterSheet: View {
    @Bindable var model: ExploreModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FilterSheetContainer(title: "Sort Order") {
            ForEach(RecipeSort.allCases) { option in
                FilterOptionCard(
                    title: option.displayName,
                    icon: sortIcon(for: option),
                    isSelected: model.sort == option
                ) {
                    model.sort = option
                    dismiss()
                }
            }
        }
        .presentationDetents([.height(420), .medium])
        .presentationDragIndicator(.visible)
    }

    private func sortIcon(for option: RecipeSort) -> String {
        switch option {
        case .newest: return "clock"
        case .oldest: return "clock.arrow.circlepath"
        case .titleAsc: return "textformat.abc"
        case .titleZ: return "textformat.abc"
        case .favoritesFirst: return "heart.fill"
        }
    }
}

// MARK: - Tags Filter Sheet

private struct TagsFilterSheet: View {
    @Bindable var model: ExploreModel

    var body: some View {
        FilterSheetContainer(title: "Filter by Tags") {
            if model.availableTags.isEmpty {
                Text("No tags created yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(model.availableTags) { tag in
                    let isSelected = model.selectedTagIDs.contains(tag.id)
                    FilterOptionCard(
                        title: tag.name,
                        icon: tag.isPCOS ? nil : "tag",
                        isPCOS: tag.isPCOS,
                        isSelected: isSelected
                    ) {
                        model.toggleTagSelection(tag.id)
                    }
                }

                if !model.selectedTagIDs.isEmpty {
                    Button {
                        model.selectedTagIDs.removeAll()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear Tag Filters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Folder Filter Sheet

private struct FolderFilterSheet: View {
    @Bindable var model: ExploreModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FilterSheetContainer(title: "Select Folder") {
            FilterOptionCard(
                title: "All Recipes",
                subtitle: "Show all recipes across all folders",
                icon: "tray.full",
                isSelected: model.selectedFolderID == nil
            ) {
                model.selectedFolderID = nil
                dismiss()
            }

            let nodes = model.hierarchicalFolders()
            ForEach(nodes) { node in
                let isSelected = model.selectedFolderID == node.folder.id
                let indentPrefix = String(repeating: "    ", count: node.depth)
                let nameWithPrefix = node.depth > 0 ? "\(indentPrefix)↳  \(node.folder.name)" : node.folder.name

                FilterOptionCard(
                    title: nameWithPrefix,
                    icon: node.depth > 0 ? "folder" : "folder.fill",
                    isSelected: isSelected
                ) {
                    model.selectedFolderID = node.folder.id
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Household Filter Sheet

private struct HouseholdFilterSheet: View {
    @Bindable var model: ExploreModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FilterSheetContainer(title: "Select Household") {
            FilterOptionCard(
                title: "All Households",
                subtitle: "Show recipes from all joined households",
                icon: "house",
                isSelected: model.selectedHouseholdID == nil
            ) {
                model.selectedHouseholdID = nil
                dismiss()
            }

            ForEach(model.joinedHouseholds) { household in
                let isSelected = model.selectedHouseholdID == household.id
                FilterOptionCard(
                    title: household.name ?? "Household",
                    icon: "house.fill",
                    isSelected: isSelected
                ) {
                    model.selectedHouseholdID = household.id
                    dismiss()
                }
            }
        }
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.visible)
    }
}
