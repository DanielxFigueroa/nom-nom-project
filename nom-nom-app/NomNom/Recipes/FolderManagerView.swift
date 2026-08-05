import SwiftUI

/// Lightweight folder manager for creating, renaming, moving (changing parent), and deleting folders.
struct FolderManagerView: View {
    let householdID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(RecipesRefresh.self) private var recipesRefresh

    @State private var folders: [Folder] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Create folder state
    @State private var showCreateSheet = false
    @State private var newFolderName = ""
    @State private var newFolderParentID: UUID?

    // Edit/Rename state
    @State private var editingFolder: Folder?
    @State private var editName = ""
    @State private var editParentID: UUID?

    // Delete confirm
    @State private var folderToDelete: Folder?

    private let repository = FoldersRepository()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if folders.isEmpty {
                    ContentUnavailableView(
                        "No Folders Created",
                        systemImage: "folder",
                        description: Text("Organize your recipes into nested folders by creating your first folder.")
                    )
                } else {
                    List {
                        ForEach(folders.buildTree()) { displayFolder in
                            folderRow(displayFolder)
                        }
                    }
                }
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        newFolderParentID = nil
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("New Folder")
                }
            }
            .task { await loadFolders() }
            .sheet(isPresented: $showCreateSheet) {
                createFolderSheet
            }
            .sheet(item: $editingFolder) { folder in
                editFolderSheet(folder: folder)
            }
            .confirmationDialog(
                "Delete folder \"\(folderToDelete?.name ?? "")\"?",
                isPresented: Binding(get: { folderToDelete != nil }, set: { if !$0 { folderToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Folder", role: .destructive) {
                    if let folder = folderToDelete {
                        Task { await deleteFolder(folder) }
                    }
                }
                Button("Cancel", role: .cancel) { folderToDelete = nil }
            } message: {
                Text("Subfolders will also be deleted. Recipes inside will remain intact but become un-filed.")
            }
        }
    }

    private func folderRow(_ displayFolder: DisplayFolder) -> some View {
        let folder = displayFolder.folder
        return HStack(spacing: 8) {
            if displayFolder.depth > 0 {
                Spacer()
                    .frame(width: CGFloat(displayFolder.depth * 16))
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.nnTint)
            Text(folder.name)
                .font(.body)

            Spacer()

            Menu {
                Button {
                    editingFolder = folder
                    editName = folder.name
                    editParentID = folder.parentId
                } label: {
                    Label("Edit Folder", systemImage: "pencil")
                }

                Button {
                    newFolderName = ""
                    newFolderParentID = folder.id
                    showCreateSheet = true
                } label: {
                    Label("Add Subfolder", systemImage: "folder.badge.plus")
                }

                Button(role: .destructive) {
                    folderToDelete = folder
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(4)
            }
        }
        .padding(.vertical, 4)
    }

    private var createFolderSheet: some View {
        NavigationStack {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $newFolderName)
                    Picker("Parent Folder", selection: $newFolderParentID) {
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

    private func editFolderSheet(folder: Folder) -> some View {
        NavigationStack {
            Form {
                Section("Edit Folder") {
                    TextField("Folder Name", text: $editName)
                    Picker("Parent Folder", selection: $editParentID) {
                        Text("None (Top level)").tag(UUID?.none)
                        ForEach(folders.buildTree().filter { $0.id != folder.id }) { df in
                            Text(String(repeating: "  ", count: df.depth) + df.name).tag(UUID?.some(df.id))
                        }
                    }
                }
            }
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { editingFolder = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveFolderEdits(folder: folder) }
                    }
                    .disabled(editName.trimmed.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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
            _ = try await repository.createFolder(name: name, parentID: newFolderParentID, householdID: householdID)
            showCreateSheet = false
            recipesRefresh.trigger()
            await loadFolders()
        } catch {
            errorMessage = "Failed to create folder."
        }
    }

    private func saveFolderEdits(folder: Folder) async {
        let name = editName.trimmed
        guard !name.isEmpty else { return }
        do {
            if name != folder.name {
                try await repository.renameFolder(id: folder.id, newName: name)
            }
            if editParentID != folder.parentId {
                // If parent changed, re-create or update
                // (Note: Supabase table update for parent_id)
                try await SupabaseManager.shared
                    .from("folders")
                    .update(["parent_id": editParentID])
                    .eq("id", value: folder.id)
                    .execute()
            }
            editingFolder = nil
            recipesRefresh.trigger()
            await loadFolders()
        } catch {
            errorMessage = "Failed to update folder."
        }
    }

    private func deleteFolder(_ folder: Folder) async {
        do {
            try await repository.deleteFolder(id: folder.id)
            folderToDelete = nil
            recipesRefresh.trigger()
            await loadFolders()
        } catch {
            errorMessage = "Failed to delete folder."
        }
    }
}
