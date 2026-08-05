import Foundation
import Supabase

/// Repository managing household folders and recipe-to-folder assignments.
struct FoldersRepository {
    private let client = SupabaseManager.shared

    private struct FolderInsert: Encodable {
        let name: String
        let parent_id: UUID?
        let household_id: UUID
    }

    private struct FolderUpdate: Encodable {
        let name: String
    }

    private struct MoveRecipeUpdate: Encodable {
        let folder_id: UUID?
    }

    /// Fetches all folders for a given household, ordered by creation date.
    func fetchFolders(householdID: UUID) async throws -> [Folder] {
        try await client
            .from("folders")
            .select("*")
            .eq("household_id", value: householdID)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    /// Creates a new folder (optionally nested under `parentID`).
    @discardableResult
    func createFolder(name: String, parentID: UUID?, householdID: UUID) async throws -> Folder {
        let payload = FolderInsert(name: name, parent_id: parentID, household_id: householdID)
        return try await client
            .from("folders")
            .insert(payload)
            .select("*")
            .single()
            .execute()
            .value
    }

    /// Renames an existing folder.
    func renameFolder(id: UUID, newName: String) async throws {
        let payload = FolderUpdate(name: newName)
        try await client
            .from("folders")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    /// Deletes a folder. Subfolders cascade delete via Postgres DB constraints,
    /// while recipes in deleted folders are un-filed (`folder_id` set to null).
    func deleteFolder(id: UUID) async throws {
        try await client
            .from("folders")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Moves a recipe to a target folder (or passes nil to un-file).
    func moveRecipe(recipeID: UUID, toFolder folderID: UUID?) async throws {
        try await client
            .from("recipes")
            .update(["folder_id": folderID])
            .eq("id", value: recipeID)
            .execute()
    }
}
