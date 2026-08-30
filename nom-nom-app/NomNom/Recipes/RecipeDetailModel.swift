import Foundation
import Observation

/// Drives the recipe detail screen. Ports RN `app/modal.tsx`.
@MainActor
@Observable
final class RecipeDetailModel {
    var recipe: Recipe
    var ingredients: [Ingredient] = []
    var tags: [Tag] = []
    var currentFolder: Folder?
    var checkedIDs: Set<UUID> = []
    var isFavorite: Bool
    var isLoading = true
    var desiredServings: Int

    // Reminders export state
    var isExportingToReminders = false
    var exportSuccessMessage: String?
    var showRemindersPermissionAlert = false
    var remindersErrorMessage: String?
    var availableReminderLists: [RemindersListInfo] = []
    var selectedListID: String?

    // PDF export state
    var isExportingPDF = false
    var exportedPDF: ExportedPDF?
    var pdfErrorMessage: String?

    private let repository = RecipesRepository()
    private let tagsRepository = TagsRepository()
    private let foldersRepository = FoldersRepository()
    private let remindersService = RemindersService.shared

    init(recipe: Recipe) {
        self.recipe = recipe
        self.isFavorite = recipe.isFavorite
        self.ingredients = recipe.ingredients ?? []
        self.desiredServings = max(recipe.servings, 1)
        self.selectedListID = UserDefaults.standard.string(forKey: "preferredRemindersListID")
    }

    var minServings: Int { 1 }

    var maxServings: Int {
        max(24, recipe.servings)
    }

    var desiredServingsDouble: Double {
        get { Double(desiredServings) }
        set { desiredServings = max(minServings, min(maxServings, Int(newValue.rounded()))) }
    }

    func incrementServings() {
        if desiredServings < maxServings {
            desiredServings += 1
        }
    }

    func decrementServings() {
        if desiredServings > minServings {
            desiredServings -= 1
        }
    }

    var scaleFactor: Double {
        Double(desiredServings) / Double(max(recipe.servings, 1))
    }

    var isServingScaled: Bool {
        desiredServings != recipe.servings
    }

    var hasLegacyUnscalableIngredients: Bool {
        ingredients.contains { $0.quantityValue == nil && !($0.quantity ?? "").isEmpty }
    }

    func formattedLabel(for ingredient: Ingredient) -> String {
        if let val = ingredient.quantityValue {
            let scaledVal = val * scaleFactor
            let qtyStr = FractionFormatter.format(scaledVal)
            return [qtyStr, ingredient.unit, ingredient.name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else {
            return [ingredient.quantity, ingredient.unit, ingredient.name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    func resetServings() {
        desiredServings = max(recipe.servings, 1)
    }

    /// Whether the recipe has the reserved PCOS tag.
    var hasPCOSTag: Bool {
        tags.contains { $0.isPCOS }
    }

    /// Fetches the full recipe + ingredients + tags + folder.
    func load() async {
        do {
            async let recipeTask = repository.fetchRecipe(id: recipe.id)
            async let ingredientsTask = repository.fetchIngredients(recipeID: recipe.id)
            async let tagsTask = tagsRepository.fetchRecipeTags(recipeID: recipe.id)
            let (fetched, fetchedIngredients, fetchedTags) = try await (recipeTask, ingredientsTask, tagsTask)
            let wasAtBaseServings = (desiredServings == max(recipe.servings, 1))
            recipe = fetched
            isFavorite = fetched.isFavorite
            ingredients = fetchedIngredients
            tags = fetchedTags
            if wasAtBaseServings {
                desiredServings = max(fetched.servings, 1)
            }
            if let fId = fetched.folderId {
                let allFolders = (try? await foldersRepository.fetchFolders(householdID: fetched.householdId)) ?? []
                currentFolder = allFolders.first { $0.id == fId }
            } else {
                currentFolder = nil
            }
        } catch {
            // Keep whatever we already have from the list row.
        }
        await loadReminderLists()
        isLoading = false
    }

    func loadReminderLists() async {
        if remindersService.checkAuthorizationStatus() == .authorized {
            if let lists = try? await remindersService.fetchReminderLists(), !lists.isEmpty {
                availableReminderLists = lists
                if selectedListID == nil || !lists.contains(where: { $0.id == selectedListID }) {
                    if let defaultList = lists.first(where: { $0.isDefault }) {
                        selectedListID = defaultList.id
                    } else {
                        selectedListID = lists.first?.id
                    }
                }
            }
        }
    }

    func selectPreferredList(_ id: String) {
        selectedListID = id
        UserDefaults.standard.set(id, forKey: "preferredRemindersListID")
    }

    var selectedListName: String? {
        if let selectedListID, let match = availableReminderLists.first(where: { $0.id == selectedListID }) {
            return match.title
        }
        return availableReminderLists.first(where: { $0.isDefault })?.title ?? availableReminderLists.first?.title
    }

    func moveToFolder(_ folderID: UUID?) async {
        do {
            try await foldersRepository.moveRecipe(recipeID: recipe.id, toFolder: folderID)
            await load()
        } catch {
            // Non-fatal
        }
    }

    func toggleChecked(_ id: UUID) {
        if checkedIDs.contains(id) {
            checkedIDs.remove(id)
        } else {
            checkedIDs.insert(id)
        }
    }

    func toggleFavorite() async {
        isFavorite.toggle()
        do {
            try await repository.setFavorite(recipeID: recipe.id, isFavorite: isFavorite)
        } catch {
            isFavorite.toggle() // revert on failure
        }
    }

    var uncheckedIngredients: [Ingredient] {
        ingredients.filter { !checkedIDs.contains($0.id) }
    }

    var hasCheckedIngredients: Bool {
        !checkedIDs.isEmpty && checkedIDs.count < ingredients.count
    }

    /// Exports ingredients (scaled to current serving size) to Apple Reminders.
    func exportToReminders(onlyUnchecked: Bool = false, targetListID: String? = nil) async {
        let itemsToExport: [Ingredient]
        if onlyUnchecked && !uncheckedIngredients.isEmpty {
            itemsToExport = uncheckedIngredients
        } else {
            itemsToExport = ingredients
        }

        guard !itemsToExport.isEmpty else { return }

        let chosenListID = targetListID ?? selectedListID
        if let targetListID {
            selectPreferredList(targetListID)
        }

        isExportingToReminders = true
        remindersErrorMessage = nil
        exportSuccessMessage = nil

        let labels = itemsToExport.map { formattedLabel(for: $0) }

        do {
            let (count, listTitle) = try await remindersService.exportIngredients(labels, toCalendarIdentifier: chosenListID)
            await loadReminderLists()
            isExportingToReminders = false
            let itemWord = count == 1 ? "ingredient" : "ingredients"
            let targetSuffix = listTitle.isEmpty ? "Reminders" : listTitle
            exportSuccessMessage = "Added \(count) \(itemWord) to \(targetSuffix)"

            Task { [weak self] in
                try? await Task.sleep(for: .seconds(3.5))
                guard let self else { return }
                if self.exportSuccessMessage != nil {
                    self.exportSuccessMessage = nil
                }
            }
        } catch RemindersError.accessDenied {
            isExportingToReminders = false
            showRemindersPermissionAlert = true
        } catch {
            isExportingToReminders = false
            remindersErrorMessage = error.localizedDescription
        }
    }

    /// Exports the full recipe as a styled PDF document and prepares it for sharing.
    func exportPDF() async {
        guard !isExportingPDF else { return }
        isExportingPDF = true
        pdfErrorMessage = nil

        do {
            let url = try await RecipePDFRenderer.generatePDF(
                recipe: recipe,
                ingredients: ingredients,
                tags: tags,
                desiredServings: desiredServings,
                scaleFactor: scaleFactor
            )
            isExportingPDF = false
            exportedPDF = ExportedPDF(url: url, title: recipe.title)
        } catch {
            isExportingPDF = false
            pdfErrorMessage = error.localizedDescription
        }
    }

    func cleanupExportedPDF() {
        if let url = exportedPDF?.url {
            try? FileManager.default.removeItem(at: url)
        }
        exportedPDF = nil
    }
}

/// Identifiable container for an exported PDF file.
struct ExportedPDF: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

