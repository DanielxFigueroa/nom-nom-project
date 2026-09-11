import Foundation
import Observation
import Supabase

/// Manages PCOS Assistant settings with local persistence in UserDefaults
/// and background synchronization with the Supabase `profiles` table.
@MainActor
@Observable
public final class PCOSSettingsStore {
    public static let shared = PCOSSettingsStore()

    private let userDefaultsKey = "nom_nom_pcos_settings"
    private let client = SupabaseManager.shared

    public var settings: PCOSSettings {
        didSet {
            saveToLocal()
        }
    }

    public var isSyncing = false

    public init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(PCOSSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = PCOSSettings()
        }
    }

    private func saveToLocal() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    /// Load remote settings from Supabase if available; merges or updates local cache.
    public func loadSettings(userID: UUID?) async {
        guard let userID else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            struct ProfileResponse: Codable {
                let pcosSettings: PCOSSettings?
                enum CodingKeys: String, CodingKey {
                    case pcosSettings = "pcos_settings"
                }
            }

            let response: ProfileResponse? = try await client
                .from("profiles")
                .select("pcos_settings")
                .eq("id", value: userID)
                .maybeSingle()
                .execute()
                .value

            if let remoteSettings = response?.pcosSettings {
                self.settings = remoteSettings
            } else if settings != PCOSSettings() {
                // If local settings were already configured before cloud sync, push them up
                await syncToSupabase(userID: userID)
            }
        } catch {
            // Keep local settings on network or decode failures
        }
    }

    /// Persist current settings to Supabase profiles table.
    public func syncToSupabase(userID: UUID) async {
        do {
            struct ProfileUpdate: Codable {
                let pcosSettings: PCOSSettings
                enum CodingKeys: String, CodingKey {
                    case pcosSettings = "pcos_settings"
                }
            }

            try await client
                .from("profiles")
                .update(ProfileUpdate(pcosSettings: settings))
                .eq("id", value: userID)
                .execute()
        } catch {
            // Failure silently handled; local UserDefaults remains source of truth
        }
    }

    public func setEnabled(_ isEnabled: Bool, userID: UUID? = nil) {
        settings.isEnabled = isEnabled
        if let userID {
            Task { await syncToSupabase(userID: userID) }
        }
    }

    public func toggleFocusArea(_ area: PCOSFocusArea, userID: UUID? = nil) {
        if settings.focusAreas.contains(area) {
            settings.focusAreas.remove(area)
        } else {
            settings.focusAreas.insert(area)
        }
        if let userID {
            Task { await syncToSupabase(userID: userID) }
        }
    }

    public func setSuggestionStyle(_ style: PCOSSuggestionStyle, userID: UUID? = nil) {
        settings.suggestionStyle = style
        if let userID {
            Task { await syncToSupabase(userID: userID) }
        }
    }
}
