import Foundation
import Observation
import SwiftUI

/// A single editable ingredient row in the form.
struct IngredientDraft: Identifiable {
    let id: UUID
    var name: String
    var quantity: String
    var unit: String
    var quantityValue: Double?

    init(id: UUID = UUID(), name: String, quantity: String = "", unit: String = "", quantityValue: Double? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.quantityValue = quantityValue ?? Self.parseQuantityValue(quantity)
    }

    var displayLabel: String {
        let qtyDisplay = formattedQuantity
        return [qtyDisplay, unit, name].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private var formattedQuantity: String {
        if let quantityValue {
            switch quantityValue {
            case 0.25: return "¼"
            case 1.0 / 3.0: return "⅓"
            case 0.5: return "½"
            case 2.0 / 3.0: return "⅔"
            case 0.75: return "¾"
            case 1.5: return "1½"
            case 2.5: return "2½"
            default:
                if quantityValue.truncatingRemainder(dividingBy: 1) == 0 {
                    return String(Int(quantityValue))
                }
                return quantity
            }
        }
        return quantity
    }

    static func parseQuantityValue(_ qty: String) -> Double? {
        let trimmed = qty.trimmed
        switch trimmed {
        case "¼": return 0.25
        case "⅓": return 1.0 / 3.0
        case "½": return 0.5
        case "⅔": return 2.0 / 3.0
        case "¾": return 0.75
        case "1½": return 1.5
        case "2½": return 2.5
        default: return Double(trimmed)
        }
    }
}

/// Shared state for the 3-step add/edit form (SPEC.md §4). Ports RN
/// `components/RecipeForm.tsx`.
@MainActor
@Observable
final class RecipeFormModel {
    enum Step: Int, CaseIterable { case details = 1, ingredients, instructions }

    var step: Step = .details

    // Step 1
    var title = ""
    var descriptionText = ""
    var insulinIndexNotes = ""
    var mealTimingSuggestions = ""
    var imageURLString: String?
    var pickedImage: Image?
    var isUploading = false

    // Step 2
    var measurementSystem: MeasurementSystem = RegionDefaults.measurementSystem()
    var ingredients: [IngredientDraft] = []
    var ingName = ""
    var ingQtyOption: QtyOption? = nil
    var ingUnit: RecipeUnit? = nil

    // Step 3
    var instructions = ""
    var showMarkdownPreview = false

    var errorMessage: String?

    private let storage = StorageService()

    static let fallbackImageURL = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400"

    /// PCOS seafood substitution keywords (ports RN `SEAFOOD_KEYWORDS`).
    static let seafoodKeywords = [
        "seafood", "shrimp", "fish", "salmon", "tuna", "crab", "lobster",
        "prawn", "cod", "haddock", "trout", "halibut", "mackerel", "sardine",
        "anchovy", "scallop", "clam", "mussel", "oyster", "squid", "octopus",
        "calamari"
    ]

    init() {}

    init(recipe: Recipe, ingredients: [Ingredient]) {
        title = recipe.title
        descriptionText = recipe.description ?? ""
        insulinIndexNotes = recipe.insulinIndexNotes ?? ""
        mealTimingSuggestions = recipe.mealTimingSuggestions ?? ""
        imageURLString = recipe.imageURL
        instructions = recipe.instructions ?? ""
        measurementSystem = recipe.measurementSystem
        self.ingredients = ingredients.map {
            IngredientDraft(id: $0.id, name: $0.name, quantity: $0.quantity ?? "", unit: $0.unit ?? "")
        }
    }

    func isSeafood(_ name: String) -> Bool {
        let cleaned = name.trimmed.lowercased()
        guard !cleaned.isEmpty else { return false }
        return Self.seafoodKeywords.contains { cleaned.contains($0) }
    }

    func addIngredient() {
        let name = ingName.trimmed
        guard !name.isEmpty else {
            errorMessage = "Ingredient name is required."
            return
        }
        let qtyStr = ingQtyOption?.label ?? ""
        let unitStr = ingUnit?.displayName ?? ""
        ingredients.append(IngredientDraft(
            name: name,
            quantity: qtyStr,
            unit: unitStr,
            quantityValue: ingQtyOption?.value
        ))
        ingName = ""
        ingQtyOption = nil
        ingUnit = nil
    }

    func removeIngredient(_ draft: IngredientDraft) {
        ingredients.removeAll { $0.id == draft.id }
    }

    func goNext() {
        switch step {
        case .details:
            guard !title.trimmed.isEmpty else {
                errorMessage = "Recipe Title is required."
                return
            }
            step = .ingredients
        case .ingredients:
            guard !ingredients.isEmpty else {
                errorMessage = "Please add at least one ingredient."
                return
            }
            step = .instructions
        case .instructions:
            break
        }
    }

    func goBack() {
        switch step {
        case .ingredients: step = .details
        case .instructions: step = .ingredients
        case .details: break
        }
    }

    func uploadImage(data: Data, preview: Image, isPNG: Bool) async {
        pickedImage = preview
        isUploading = true
        do {
            imageURLString = try await storage.uploadRecipeImage(data: data, isPNG: isPNG)
        } catch {
            errorMessage = "Failed to upload image. Keeping the selected image may not persist."
        }
        isUploading = false
    }

    /// Validates all steps and builds the submit payload; nil (with errorMessage) if invalid.
    func buildPayload() -> (RecipeInput, [IngredientInput])? {
        guard !title.trimmed.isEmpty else {
            errorMessage = "Recipe Title is required."
            return nil
        }
        guard !ingredients.isEmpty else {
            errorMessage = "Please add at least one ingredient."
            return nil
        }
        guard !instructions.trimmed.isEmpty else {
            errorMessage = "Recipe instructions are required."
            return nil
        }
        let input = RecipeInput(
            title: title.trimmed,
            description: descriptionText.trimmed,
            instructions: instructions.trimmed,
            imageURL: (imageURLString?.nilIfEmpty) ?? Self.fallbackImageURL,
            insulinIndexNotes: insulinIndexNotes.trimmed.nilIfEmpty,
            mealTimingSuggestions: mealTimingSuggestions.trimmed.nilIfEmpty,
            measurementSystem: measurementSystem
        )
        let ings = ingredients.map {
            IngredientInput(name: $0.name, quantity: $0.quantity.nilIfEmpty, unit: $0.unit.nilIfEmpty)
        }
        return (input, ings)
    }
}

