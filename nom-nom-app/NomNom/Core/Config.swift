import Foundation

/// Reads Supabase configuration injected via `Secrets.xcconfig` → Info.plist.
/// See `Resources/Secrets.example.xcconfig`.
enum Config {
    static let supabaseURL: URL = {
        guard let raw = infoString("SUPABASE_URL"), let url = URL(string: raw) else {
            fatalError("Missing/invalid SUPABASE_URL — set it in NomNom/Resources/Secrets.xcconfig")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = infoString("SUPABASE_ANON_KEY"), !key.isEmpty, key != "PLACEHOLDER" else {
            fatalError("Missing SUPABASE_ANON_KEY — set it in NomNom/Resources/Secrets.xcconfig")
        }
        return key
    }()

    private static func infoString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
