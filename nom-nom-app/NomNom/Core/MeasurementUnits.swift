import Foundation

enum MeasurementSystem: String, CaseIterable, Codable, Identifiable {
    case imperial
    case metric

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric: return "Metric"
        }
    }
}

enum RecipeUnit: String, CaseIterable, Codable, Identifiable {
    // Shared / count
    case piece
    case clove
    case slice
    case pinch
    case dash
    case toTaste

    // Shared volume
    case tsp
    case tbsp

    // Imperial
    case cup
    case flOz
    case pint
    case quart
    case oz
    case lb

    // Metric
    case ml
    case liter
    case g
    case kg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .piece: return "piece"
        case .clove: return "clove"
        case .slice: return "slice"
        case .pinch: return "pinch"
        case .dash: return "dash"
        case .toTaste: return "to taste"
        case .tsp: return "tsp"
        case .tbsp: return "tbsp"
        case .cup: return "cup"
        case .flOz: return "fl oz"
        case .pint: return "pt"
        case .quart: return "qt"
        case .oz: return "oz"
        case .lb: return "lb"
        case .ml: return "ml"
        case .liter: return "l"
        case .g: return "g"
        case .kg: return "kg"
        }
    }

    static func options(for system: MeasurementSystem) -> [RecipeUnit] {
        let shared: [RecipeUnit] = [.piece, .clove, .slice, .pinch, .dash, .toTaste, .tsp, .tbsp]
        switch system {
        case .imperial:
            return shared + [.cup, .flOz, .pint, .quart, .oz, .lb]
        case .metric:
            return shared + [.ml, .liter, .g, .kg]
        }
    }

    static func from(string: String?) -> RecipeUnit? {
        guard let raw = string?.trimmed, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        return RecipeUnit.allCases.first { unit in
            unit.rawValue.lowercased() == lower || unit.displayName.lowercased() == lower
        }
    }
}

struct QtyOption: Identifiable, Hashable, Equatable {
    let value: Double?
    let label: String

    var id: String { label }

    static let all: [QtyOption] = [
        QtyOption(value: 0.25, label: "¼"),
        QtyOption(value: 1.0 / 3.0, label: "⅓"),
        QtyOption(value: 0.5, label: "½"),
        QtyOption(value: 2.0 / 3.0, label: "⅔"),
        QtyOption(value: 0.75, label: "¾"),
        QtyOption(value: 1.0, label: "1"),
        QtyOption(value: 1.5, label: "1½"),
        QtyOption(value: 2.0, label: "2"),
        QtyOption(value: 2.5, label: "2½"),
        QtyOption(value: 3.0, label: "3"),
        QtyOption(value: 4.0, label: "4"),
        QtyOption(value: 5.0, label: "5"),
        QtyOption(value: 6.0, label: "6"),
        QtyOption(value: 7.0, label: "7"),
        QtyOption(value: 8.0, label: "8"),
        QtyOption(value: 9.0, label: "9"),
        QtyOption(value: 10.0, label: "10"),
    ]

    static func from(string: String?) -> QtyOption? {
        guard let raw = string?.trimmed, !raw.isEmpty else { return nil }
        return QtyOption.all.first { opt in
            opt.label == raw || (opt.value != nil && String(opt.value!) == raw)
        }
    }
}
