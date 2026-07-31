import Foundation
import Supabase

/// Uploads recipe images to the public `recipes` storage bucket
/// (ports the upload flow in RN `components/RecipeForm.tsx`).
struct StorageService {
    private let client = SupabaseManager.shared

    /// Uploads image data and returns its public URL string.
    func uploadRecipeImage(data: Data, isPNG: Bool) async throws -> String {
        let ext = isPNG ? "png" : "jpg"
        let contentType = isPNG ? "image/png" : "image/jpeg"
        let path = "\(UUID().uuidString)-\(Int(Date().timeIntervalSince1970)).\(ext)"

        try await client.storage
            .from("recipes")
            .upload(path, data: data, options: FileOptions(contentType: contentType, upsert: true))

        return try client.storage.from("recipes").getPublicURL(path: path).absoluteString
    }
}
