import Foundation
import Observation
import SwiftUI

/// A single editable ingredient row in the form.
struct IngredientDraft: Identifiable {
    let id: UUID
    var name: String
    var quantity: String
    var unit: String

    init(id: UUID = UUID(), name: String, quantity: String = "", unit: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }

    var displayLabel: String {
        [quantity, unit, name].filter { !$0.isEmpty }.joined(separator: " ")
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
    var ingredients: [IngredientDraft] = []
    var ingName = ""
    var ingQty = ""
    var ingUnit = ""

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
        ingredients.append(IngredientDraft(name: name, quantity: ingQty.trimmed, unit: ingUnit.trimmed))
        ingName = ""
        ingQty = ""
        ingUnit = ""
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
            mealTimingSuggestions: mealTimingSuggestions.trimmed.nilIfEmpty
        )
        let ings = ingredients.map {
            IngredientInput(name: $0.name, quantity: $0.quantity.nilIfEmpty, unit: $0.unit.nilIfEmpty)
        }
        return (input, ings)
    }
}
