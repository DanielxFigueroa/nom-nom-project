import SwiftUI

/// Horizontal row of pill-shaped dropdown controls for Explore (Sort, Tags, Folder).
struct PillFilterBar: View {
    @Bindable var model: ExploreModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1. Sort Pill
                sortPill

                // 2. Tags Pill
                tagsPill

                // 3. Folder Pill
                folderPill

                // 4. Reset Button (shown when any filter is active)
                if model.hasActiveFilters {
                    resetButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    private var sortPill: some View {
        PillDropdown(
            icon: "arrow.up.arrow.down",
            label: model.sort == .newest ? "Sort" : model.sort.displayName,
            isActive: model.sort != .newest
        ) {
            Picker("Sort Order", selection: $model.sort) {
                ForEach(RecipeSort.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        }
    }

    private var tagsPill: some View {
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

        return PillDropdown(
            icon: "tag",
            label: tagLabel,
            isActive: selectedCount > 0
        ) {
            if selectedCount > 0 {
                Button("Clear Tag Filters") {
                    model.selectedTagIDs.removeAll()
                }
                Divider()
            }

            if model.availableTags.isEmpty {
                Text("No Tags Created")
                    .foregroundColor(.secondary)
            } else {
                ForEach(model.availableTags) { tag in
                    let isSelected = model.selectedTagIDs.contains(tag.id)
                    Button {
                        model.toggleTagSelection(tag.id)
                    } label: {
                        HStack {
                            if tag.isPCOS {
                                Image(systemName: "sparkles")
                            }
                            Text(tag.name)
                            if isSelected {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    private var folderPill: some View {
        let isFolderActive = model.selectedFolderID != nil
        let folderLabel = model.selectedFolder?.name ?? "Folder"

        return PillDropdown(
            icon: isFolderActive ? "folder.fill" : "folder",
            label: folderLabel,
            isActive: isFolderActive
        ) {
            Button {
                model.selectedFolderID = nil
            } label: {
                HStack {
                    Text("All Recipes")
                    if model.selectedFolderID == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            let nodes = model.hierarchicalFolders()
            if !nodes.isEmpty {
                Divider()
                ForEach(nodes) { node in
                    let isSelected = model.selectedFolderID == node.folder.id
                    let prefix = String(repeating: "   ", count: node.depth) + (node.depth > 0 ? "↳ " : "")
                    Button {
                        model.selectedFolderID = node.folder.id
                    } label: {
                        HStack {
                            Text("\(prefix)\(node.folder.name)")
                            if isSelected {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    private var resetButton: some View {
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
        }
        .buttonStyle(.plain)
    }
}
