import Foundation
import Supabase

/// Single shared Supabase client. The SDK persists the auth session in the
/// Keychain automatically (this replaces the RN app's AsyncStorage setup).
enum SupabaseManager {
    static let shared = SupabaseClient(
        supabaseURL: Config.supabaseURL,
        supabaseKey: Config.supabaseAnonKey
    )
}
