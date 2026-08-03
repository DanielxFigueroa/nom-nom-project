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

    var numericQuantityString: String? {
        if let val = quantityValue ?? Self.parseQuantityValue(quantity) {
            if val.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(val))
            } else {
                let formatted = String(format: "%.3f", val)
                return formatted.replacingOccurrences(of: "(?<=\\.\\d*?)0+$", with: "", options: .regularExpression)
                                .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
            }
        }
        return quantity.nilIfEmpty
    }

    private var formattedQuantity: String {
        if let val = quantityValue ?? Self.parseQuantityValue(quantity) {
            if abs(val - 0.25) < 0.001 { return "¼" }
            if abs(val - 1.0 / 3.0) < 0.01 { return "⅓" }
            if abs(val - 0.5) < 0.001 { return "½" }
            if abs(val - 2.0 / 3.0) < 0.01 { return "⅔" }
            if abs(val - 0.75) < 0.001 { return "¾" }
            if abs(val - 1.5) < 0.001 { return "1½" }
            if abs(val - 2.5) < 0.001 { return "2½" }
            if val.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(val))
            }
            return String(val)
        }
        return quantity
    }

    static func parseQuantityValue(_ qty: String) -> Double? {
        let trimmed = qty.trimmed
        switch trimmed {
        case "¼", "1/4": return 0.25
        case "⅓", "1/3": return 1.0 / 3.0
        case "½", "1/2": return 0.5
        case "⅔", "2/3": return 2.0 / 3.0
        case "¾", "3/4": return 0.75
        case "1½", "1 1/2": return 1.5
        case "2½", "2 1/2": return 2.5
        default:
            if let val = Double(trimmed) {
                if abs(val - 1.0 / 3.0) < 0.01 { return 1.0 / 3.0 }
                if abs(val - 2.0 / 3.0) < 0.01 { return 2.0 / 3.0 }
                return val
            }
            return nil
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
    var servings: Int = 4
    var imageURLString: String?
    var pickedImage: Image?
    var isUploading = false

    // Tags
    var selectedTagIDs: Set<UUID> = []
    var isPCOS: Bool = false
    var availableTags: [Tag] = []
    var pcosTag: Tag?
    var newTagName = ""

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
    private let tagsRepository = TagsRepository()

    static let fallbackImageURL = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400"

    /// PCOS seafood substitution keywords (ports RN `SEAFOOD_KEYWORDS`).
    static let seafoodKeywords = [
        "seafood", "shrimp", "fish", "salmon", "tuna", "crab", "lobster",
        "prawn", "cod", "haddock", "trout", "halibut", "mackerel", "sardine",
        "anchovy", "scallop", "clam", "mussel", "oyster", "squid", "octopus",
        "calamari"
    ]

    init() {}

    init(recipe: Recipe, ingredients: [Ingredient], recipeTags: [Tag] = []) {
        title = recipe.title
        descriptionText = recipe.description ?? ""
        servings = recipe.servings
        imageURLString = recipe.imageURL
        instructions = recipe.instructions ?? ""
        measurementSystem = recipe.measurementSystem
        self.ingredients = ingredients.map {
            IngredientDraft(id: $0.id, name: $0.name, quantity: $0.quantity ?? "", unit: $0.unit ?? "", quantityValue: $0.quantityValue)
        }
        // Populate tag state from existing recipe tags.
        selectedTagIDs = Set(recipeTags.map { $0.id })
        isPCOS = recipeTags.contains { $0.isPCOS }
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
        // Build final tag ID list: include selected tags, and ensure the PCOS
        // tag is added/removed based on the toggle.
        var finalTagIDs = selectedTagIDs
        if let pcosTag {
            if isPCOS {
                finalTagIDs.insert(pcosTag.id)
            } else {
                finalTagIDs.remove(pcosTag.id)
            }
        }
        let input = RecipeInput(
            title: title.trimmed,
            description: descriptionText.trimmed,
            instructions: instructions.trimmed,
            imageURL: (imageURLString?.nilIfEmpty) ?? Self.fallbackImageURL,
            measurementSystem: measurementSystem,
            servings: max(1, servings),
            tagIDs: Array(finalTagIDs)
        )
        let ings = ingredients.map {
            IngredientInput(name: $0.name, quantity: $0.numericQuantityString, unit: $0.unit.nilIfEmpty, quantityValue: $0.quantityValue)
        }
        return (input, ings)
    }

    // MARK: - Tag Management

    /// Loads available household tags and ensures the reserved PCOS tag exists.
    func loadTags(householdID: UUID) async {
        do {
            let pcos = try await tagsRepository.ensurePCOSTag(householdID: householdID)
            pcosTag = pcos
            availableTags = try await tagsRepository.fetchTags(householdID: householdID)
        } catch {
            // Tags are non-critical; the form can still work without them.
        }
    }

    /// Loads the tags that are currently on a recipe (for edit mode).
    func loadRecipeTags(recipeID: UUID) async {
        do {
            let tags = try await tagsRepository.fetchRecipeTags(recipeID: recipeID)
            selectedTagIDs = Set(tags.map { $0.id })
            isPCOS = tags.contains { $0.isPCOS }
        } catch {
            // Non-critical.
        }
    }

    /// Creates a new tag inline and adds it to the selection.
    func createAndSelectTag(householdID: UUID) async {
        let name = newTagName.trimmed
        guard !name.isEmpty else { return }
        do {
            let tag = try await tagsRepository.createTag(name: name, householdID: householdID)
            availableTags.append(tag)
            selectedTagIDs.insert(tag.id)
            newTagName = ""
        } catch {
            errorMessage = "Failed to create tag."
        }
    }

    func toggleTag(_ tagID: UUID) {
        if selectedTagIDs.contains(tagID) {
            selectedTagIDs.remove(tagID)
            // If it's the PCOS tag, also toggle the flag.
            if tagID == pcosTag?.id {
                isPCOS = false
            }
        } else {
            selectedTagIDs.insert(tagID)
            if tagID == pcosTag?.id {
                isPCOS = true
            }
        }
    }
}

