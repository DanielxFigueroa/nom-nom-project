import Foundation
import EventKit

enum RemindersAuthStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
}

enum RemindersError: LocalizedError {
    case accessDenied
    case accessRestricted
    case noCalendarAvailable
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to Reminders was denied. Please allow Reminders access in iOS Settings."
        case .accessRestricted:
            return "Access to Reminders is restricted on this device."
        case .noCalendarAvailable:
            return "No Reminders list is available to save items."
        case .saveFailed(let message):
            return "Failed to save reminders: \(message)"
        }
    }
}

/// Service handling Apple Reminders authorization and item creation.
final class RemindersService {
    static let shared = RemindersService()
    private let eventStore = EKEventStore()

    func checkAuthorizationStatus() -> RemindersAuthStatus {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        case .writeOnly:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    func requestAuthorization() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToReminders()
        } else {
            return try await eventStore.requestAccess(to: .reminder)
        }
    }

    /// Exports an array of formatted ingredient strings to the user's Reminders list.
    func exportIngredients(_ items: [String], listTitle: String? = nil) async throws -> Int {
        guard !items.isEmpty else { return 0 }

        let status = checkAuthorizationStatus()
        switch status {
        case .notDetermined:
            let granted = try await requestAuthorization()
            guard granted else {
                throw RemindersError.accessDenied
            }
        case .denied:
            throw RemindersError.accessDenied
        case .restricted:
            throw RemindersError.accessRestricted
        case .authorized:
            break
        }

        let targetCalendar = eventStore.defaultCalendarForNewReminders()
            ?? eventStore.calendars(for: .reminder).first(where: { $0.title == "Reminders" })
            ?? eventStore.calendars(for: .reminder).first

        guard let calendar = targetCalendar else {
            throw RemindersError.noCalendarAvailable
        }

        for item in items {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = item
            reminder.calendar = calendar
            try eventStore.save(reminder, commit: false)
        }

        try eventStore.commit()
        return items.count
    }
}
