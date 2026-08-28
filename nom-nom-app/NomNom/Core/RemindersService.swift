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

/// Represents an available list in Apple Reminders.
struct RemindersListInfo: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let isDefault: Bool
}

/// Service handling Apple Reminders authorization, list discovery, and item creation.
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

    /// Fetches all accessible reminder lists for the user.
    func fetchReminderLists() async throws -> [RemindersListInfo] {
        let status = checkAuthorizationStatus()
        switch status {
        case .notDetermined:
            let granted = try await requestAuthorization()
            guard granted else { return [] }
        case .authorized:
            break
        case .denied, .restricted:
            return []
        }

        let calendars = eventStore.calendars(for: .reminder)
        let defaultCalendar = eventStore.defaultCalendarForNewReminders()

        return calendars.map { calendar in
            RemindersListInfo(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                isDefault: calendar.calendarIdentifier == defaultCalendar?.calendarIdentifier
            )
        }.sorted { (a, b) -> Bool in
            if a.isDefault != b.isDefault {
                return a.isDefault && !b.isDefault
            }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    /// Exports an array of formatted ingredient strings to the specified or default Reminders list.
    /// Returns the number of items created and the destination list title.
    func exportIngredients(_ items: [String], toCalendarIdentifier calendarID: String? = nil) async throws -> (count: Int, listTitle: String) {
        guard !items.isEmpty else { return (0, "") }

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

        let allCalendars = eventStore.calendars(for: .reminder)
        let targetCalendar: EKCalendar?
        if let calendarID = calendarID {
            targetCalendar = allCalendars.first { $0.calendarIdentifier == calendarID }
                ?? eventStore.defaultCalendarForNewReminders()
                ?? allCalendars.first
        } else {
            targetCalendar = eventStore.defaultCalendarForNewReminders()
                ?? allCalendars.first(where: { $0.title == "Reminders" })
                ?? allCalendars.first
        }

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
        return (items.count, calendar.title)
    }
}
