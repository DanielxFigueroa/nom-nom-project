import Foundation
import Supabase

/// Human-readable message for an error, surfacing Supabase specifics
/// (Postgres/RLS message + code + hint, or storage message) when available.
func describeError(_ error: Error) -> String {
    if let e = error as? PostgrestError {
        var parts = [e.message]
        if let code = e.code { parts.append("code: \(code)") }
        if let hint = e.hint { parts.append("hint: \(hint)") }
        return parts.joined(separator: "\n")
    }
    if let e = error as? StorageError {
        return e.message
    }
    return error.localizedDescription
}
