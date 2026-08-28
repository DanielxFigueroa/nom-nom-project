import SwiftUI

struct DisplayFolder: Identifiable {
    let folder: Folder
    let depth: Int
    var id: UUID { folder.id }
    var name: String { folder.name }
}

extension Array where Element == Folder {
    func buildTree() -> [DisplayFolder] {
        var result: [DisplayFolder] = []
        func appendChildren(parentId: UUID?, depth: Int) {
            let children = self.filter { $0.parentId == parentId }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            for child in children {
                result.append(DisplayFolder(folder: child, depth: depth))
                appendChildren(parentId: child.id, depth: depth + 1)
            }
        }
        appendChildren(parentId: nil, depth: 0)
        return result
    }
}

/// Sheet for picking a destination folder for a recipe.
/// Supports selecting "None", existing folders (with tree indentation), or inline creation of a new folder.
struct FolderPickerSheet: View {
    let currentFolderID: UUID?
    let householdID: UUID
    let onSelectFolder: (UUID?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var folders: [Folder] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var newFolderName = ""
    @State private var selectedParentID: UUID? = nil
    @State private var errorMessage: String?

    private let repository = FoldersRepository()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        Section {
                            Button {
                                onSelectFolder(nil)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundStyle(.secondary)
                                    Text("None (Un-filed)")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if currentFolderID == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.nnTint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if !folders.isEmpty {
                            Section("Folders") {
                                ForEach(folders.buildTree()) { displayFolder in
                                    Button {
                                        onSelectFolder(displayFolder.id)
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 8) {
                                            if displayFolder.depth > 0 {
                                                Spacer()
                                                    .frame(width: CGFloat(displayFolder.depth * 16))
                                                Image(systemName: "arrow.turn.down.right")
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                            }
                                            Image(systemName: "folder.fill")
                                                .foregroundStyle(Color.nnTint)
                                            Text(displayFolder.name)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            if currentFolderID == displayFolder.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(Color.nnTint)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Section {
                            Button {
                                newFolderName = ""
                                selectedParentID = currentFolderID
                                showCreateSheet = true
                            } label: {
                                Label("New Folder…", systemImage: "folder.badge.plus")
                                    .foregroundStyle(Color.nnTint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadFolders() }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    Form {
                        Section("Folder Details") {
                            TextField("Folder Name", text: $newFolderName)
                            Picker("Parent Folder", selection: $selectedParentID) {
                                Text("None (Top level)").tag(UUID?.none)
                                ForEach(folders.buildTree()) { df in
                                    Text(String(repeating: "  ", count: df.depth) + df.name).tag(UUID?.some(df.id))
                                }
                            }
                        }
                    }
                    .navigationTitle("New Folder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showCreateSheet = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Create") {
                                Task { await createFolder() }
                            }
                            .disabled(newFolderName.trimmed.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func loadFolders() async {
        isLoading = true
        do {
            folders = try await repository.fetchFolders(householdID: householdID)
        } catch {
            errorMessage = "Failed to load folders."
        }
        isLoading = false
    }

    private func createFolder() async {
        let name = newFolderName.trimmed
        guard !name.isEmpty else { return }
        do {
            let created = try await repository.createFolder(name: name, parentID: selectedParentID, householdID: householdID)
            showCreateSheet = false
            onSelectFolder(created.id)
            dismiss()
        } catch {
            errorMessage = "Failed to create folder."
        }
    }
}
