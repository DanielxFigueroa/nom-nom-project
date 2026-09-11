import Foundation

/// User preferences and opt-in settings for the PCOS Recipe Assistant.
public struct PCOSSettings: Codable, Equatable, Hashable, Sendable {
    public var isEnabled: Bool
    public var focusAreas: Set<PCOSFocusArea>
    public var suggestionStyle: PCOSSuggestionStyle

    public init(
        isEnabled: Bool = false,
        focusAreas: Set<PCOSFocusArea> = [],
        suggestionStyle: PCOSSuggestionStyle = .gentleAdditions
    ) {
        self.isEnabled = isEnabled
        self.focusAreas = focusAreas
        self.suggestionStyle = suggestionStyle
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case focusAreas = "focus_areas"
        case suggestionStyle = "suggestion_style"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        self.focusAreas = try container.decodeIfPresent(Set<PCOSFocusArea>.self, forKey: .focusAreas) ?? []
        self.suggestionStyle = try container.decodeIfPresent(PCOSSuggestionStyle.self, forKey: .suggestionStyle) ?? .gentleAdditions
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(focusAreas, forKey: .focusAreas)
        try container.encode(suggestionStyle, forKey: .suggestionStyle)
    }
}

/// Personalized health focus areas for tailored PCOS suggestions.
public enum PCOSFocusArea: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case insulinResistance = "insulin_resistance"
    case inflammation = "inflammation"
    case highProtein = "high_protein"
    case dairySensitivity = "dairy_sensitivity"
    case glutenSensitivity = "gluten_sensitivity"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .insulinResistance:
            return "Insulin Resistance"
        case .inflammation:
            return "Anti-Inflammatory"
        case .highProtein:
            return "High Protein"
        case .dairySensitivity:
            return "Dairy Sensitivity"
        case .glutenSensitivity:
            return "Gluten Sensitivity"
        }
    }

    public var iconName: String {
        switch self {
        case .insulinResistance:
            return "bolt.shield.fill"
        case .inflammation:
            return "leaf.fill"
        case .highProtein:
            return "figure.run"
        case .dairySensitivity:
            return "cup.and.saucer.fill"
        case .glutenSensitivity:
            return "sparkles"
        }
    }

    public var shortDescription: String {
        switch self {
        case .insulinResistance:
            return "Focus on low glycemic impact and fiber pairing"
        case .inflammation:
            return "Prioritize antioxidant and omega-rich foods"
        case .highProtein:
            return "Optimize protein distribution for satiety and muscle mass"
        case .dairySensitivity:
            return "Highlight dairy-free and plant-based alternatives"
        case .glutenSensitivity:
            return "Highlight gluten-free whole grain substitutions"
        }
    }
}

/// The delivery style for AI recipe modifications and suggestions.
public enum PCOSSuggestionStyle: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case gentleAdditions = "gentle_additions"     // "Add before you subtract"
    case directSwaps = "direct_swaps"             // Suggest direct ingredient replacements

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gentleAdditions:
            return "Gentle Additions"
        case .directSwaps:
            return "Direct Swaps"
        }
    }

    public var subtitle: String {
        switch self {
        case .gentleAdditions:
            return "Add before you subtract"
        case .directSwaps:
            return "Ingredient replacements"
        }
    }

    public var description: String {
        switch self {
        case .gentleAdditions:
            return "Adds nutrient-dense ingredients (like fiber, healthy fats, or protein) without removing existing components."
        case .directSwaps:
            return "Replaces higher glycemic or sensitive ingredients with direct, PCOS-friendly alternatives."
        }
    }
}
