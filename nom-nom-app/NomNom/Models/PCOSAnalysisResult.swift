import Foundation

/// Structured output model representing on-device AI nutritional analysis for PCOS management.
public struct PCOSAnalysisResult: Codable, Equatable, Hashable, Sendable {
    /// Suggestion for an ingredient swap or nutrient-dense addition.
    public struct SwapSuggestion: Codable, Identifiable, Equatable, Hashable, Sendable {
        public var id: String { originalIngredient }
        public let originalIngredient: String
        public let suggestedSwap: String
        public let rationale: String
        public let adjustedQuantity: String?
        public let adjustedUnit: String?

        public init(
            originalIngredient: String,
            suggestedSwap: String,
            rationale: String,
            adjustedQuantity: String? = nil,
            adjustedUnit: String? = nil
        ) {
            self.originalIngredient = originalIngredient
            self.suggestedSwap = suggestedSwap
            self.rationale = rationale
            self.adjustedQuantity = adjustedQuantity
            self.adjustedUnit = adjustedUnit
        }

        enum CodingKeys: String, CodingKey {
            case originalIngredient = "original_ingredient"
            case originalIngredientCamel = "originalIngredient"
            case suggestedSwap = "suggested_swap"
            case suggestedSwapCamel = "suggestedSwap"
            case rationale
            case adjustedQuantity = "adjusted_quantity"
            case adjustedQuantityCamel = "adjustedQuantity"
            case adjustedUnit = "adjusted_unit"
            case adjustedUnitCamel = "adjustedUnit"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let orig = try? container.decode(String.self, forKey: .originalIngredient) {
                self.originalIngredient = orig
            } else if let origCamel = try? container.decode(String.self, forKey: .originalIngredientCamel) {
                self.originalIngredient = origCamel
            } else {
                self.originalIngredient = try container.decode(String.self, forKey: .originalIngredient)
            }

            if let swap = try? container.decode(String.self, forKey: .suggestedSwap) {
                self.suggestedSwap = swap
            } else if let swapCamel = try? container.decode(String.self, forKey: .suggestedSwapCamel) {
                self.suggestedSwap = swapCamel
            } else {
                self.suggestedSwap = try container.decode(String.self, forKey: .suggestedSwap)
            }

            self.rationale = try container.decode(String.self, forKey: .rationale)

            self.adjustedQuantity = (try? container.decodeIfPresent(String.self, forKey: .adjustedQuantity))
                ?? (try? container.decodeIfPresent(String.self, forKey: .adjustedQuantityCamel))

            self.adjustedUnit = (try? container.decodeIfPresent(String.self, forKey: .adjustedUnit))
                ?? (try? container.decodeIfPresent(String.self, forKey: .adjustedUnitCamel))
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(originalIngredient, forKey: .originalIngredient)
            try container.encode(suggestedSwap, forKey: .suggestedSwap)
            try container.encode(rationale, forKey: .rationale)
            try container.encodeIfPresent(adjustedQuantity, forKey: .adjustedQuantity)
            try container.encodeIfPresent(adjustedUnit, forKey: .adjustedUnit)
        }
    }

    public let summaryNote: String
    public let glycemicImpactBadge: String // e.g. "Blood Sugar Balanced", "Moderate Glycemic", "High Glycemic"
    public let swaps: [SwapSuggestion]
    public let pairingTips: [String]
    public let positiveHighlights: [String]

    public init(
        summaryNote: String,
        glycemicImpactBadge: String,
        swaps: [SwapSuggestion] = [],
        pairingTips: [String] = [],
        positiveHighlights: [String] = []
    ) {
        self.summaryNote = summaryNote
        self.glycemicImpactBadge = glycemicImpactBadge
        self.swaps = swaps
        self.pairingTips = pairingTips
        self.positiveHighlights = positiveHighlights
    }

    enum CodingKeys: String, CodingKey {
        case summaryNote = "summary_note"
        case summaryNoteCamel = "summaryNote"
        case glycemicImpactBadge = "glycemic_impact_badge"
        case glycemicImpactBadgeCamel = "glycemicImpactBadge"
        case swaps
        case pairingTips = "pairing_tips"
        case pairingTipsCamel = "pairingTips"
        case positiveHighlights = "positive_highlights"
        case positiveHighlightsCamel = "positiveHighlights"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let note = try? container.decode(String.self, forKey: .summaryNote) {
            self.summaryNote = note
        } else if let noteCamel = try? container.decode(String.self, forKey: .summaryNoteCamel) {
            self.summaryNote = noteCamel
        } else {
            self.summaryNote = try container.decode(String.self, forKey: .summaryNote)
        }

        if let badge = try? container.decode(String.self, forKey: .glycemicImpactBadge) {
            self.glycemicImpactBadge = badge
        } else if let badgeCamel = try? container.decode(String.self, forKey: .glycemicImpactBadgeCamel) {
            self.glycemicImpactBadge = badgeCamel
        } else {
            self.glycemicImpactBadge = try container.decode(String.self, forKey: .glycemicImpactBadge)
        }

        self.swaps = (try? container.decodeIfPresent([SwapSuggestion].self, forKey: .swaps)) ?? []

        if let tips = try? container.decodeIfPresent([String].self, forKey: .pairingTips) {
            self.pairingTips = tips
        } else if let tipsCamel = try? container.decodeIfPresent([String].self, forKey: .pairingTipsCamel) {
            self.pairingTips = tipsCamel
        } else {
            self.pairingTips = []
        }

        if let highlights = try? container.decodeIfPresent([String].self, forKey: .positiveHighlights) {
            self.positiveHighlights = highlights
        } else if let highlightsCamel = try? container.decodeIfPresent([String].self, forKey: .positiveHighlightsCamel) {
            self.positiveHighlights = highlightsCamel
        } else {
            self.positiveHighlights = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(summaryNote, forKey: .summaryNote)
        try container.encode(glycemicImpactBadge, forKey: .glycemicImpactBadge)
        try container.encode(swaps, forKey: .swaps)
        try container.encode(pairingTips, forKey: .pairingTips)
        try container.encode(positiveHighlights, forKey: .positiveHighlights)
    }

    public var isBloodSugarBalanced: Bool {
        glycemicImpactBadge.localizedCaseInsensitiveContains("balanced") ||
        glycemicImpactBadge.localizedCaseInsensitiveContains("low")
    }

    public static let mock = PCOSAnalysisResult(
        summaryNote: "This recipe has a fantastic foundation of healthy fats and micronutrients. Pairing it with leafy greens or a gentle protein boost keeps glucose levels steady.",
        glycemicImpactBadge: "Blood Sugar Balanced",
        swaps: [
            SwapSuggestion(
                originalIngredient: "White Rice",
                suggestedSwap: "Quinoa or Cauliflower Rice Blend",
                rationale: "Increases fiber and lowers the glycemic load to avoid rapid insulin spikes.",
                adjustedQuantity: "1",
                adjustedUnit: "cup"
            )
        ],
        pairingTips: [
            "Eat veggies and protein first before starches to flatten post-meal glucose response.",
            "Add a dash of apple cider vinegar in water or dressing before eating."
        ],
        positiveHighlights: [
            "Rich in dietary fiber and essential healthy fats.",
            "High in magnesium and zinc for metabolic regulation."
        ]
    )
}
