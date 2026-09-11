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

    // PCOS Assistant state
    var pcosAnalysisState: LoadingState<PCOSAnalysisResult> = .idle
    var isPCOSInsightsExpanded: Bool = true
    var appliedSwapIDs: Set<String> = []
    var lastAppliedSwapBackup: (swap: PCOSAnalysisResult.SwapSuggestion, previousIngredients: [Ingredient], previousRecipe: Recipe)?
    var isApplyingSwap: Bool = false
    var swapSuccessMessage: String?
    var swapErrorMessage: String?

    var isForkingVariation: Bool = false
    var forkSuccessMessage: String?
    var forkErrorMessage: String?
    let pcosSettingsStore: PCOSSettingsStore
    private let pcosService: PCOSService

    private let repository = RecipesRepository()
    private let tagsRepository = TagsRepository()
    private let foldersRepository = FoldersRepository()
    private let remindersService = RemindersService.shared

    init(
        recipe: Recipe,
        pcosSettingsStore: PCOSSettingsStore = .shared,
        pcosService: PCOSService = .shared
    ) {
        self.recipe = recipe
        self.pcosSettingsStore = pcosSettingsStore
        self.pcosService = pcosService
        self.isFavorite = recipe.isFavorite
        self.ingredients = recipe.ingredients ?? []
        self.desiredServings = max(recipe.servings, 1)
        self.selectedListID = UserDefaults.standard.string(forKey: "preferredRemindersListID")
    }

    /// Whether the user has opted into the PCOS Recipe Assistant.
    var isPCOSEnabled: Bool {
        pcosSettingsStore.settings.isEnabled
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
        if isPCOSEnabled {
            await loadPCOSAnalysis()
        }
        isLoading = false
    }

    /// Triggers or re-evaluates PCOS analysis using on-device intelligence.
    func loadPCOSAnalysis(forceRefresh: Bool = false) async {
        guard isPCOSEnabled else {
            pcosAnalysisState = .idle
            return
        }

        if !forceRefresh, case .loaded = pcosAnalysisState {
            return
        }

        pcosAnalysisState = .loading

        if forceRefresh {
            pcosService.invalidateCache(for: recipe.id)
        }

        do {
            let result = try await pcosService.analyze(
                recipe: recipe,
                ingredients: ingredients,
                settings: pcosSettingsStore.settings
            )
            pcosAnalysisState = .loaded(result)
        } catch {
            pcosAnalysisState = .failed(error.localizedDescription)
        }
    }

    func togglePCOSInsightsExpanded() {
        isPCOSInsightsExpanded.toggle()
    }

    // MARK: - PCOS Swaps & Forking

    func makeRecipeInput() -> RecipeInput {
        RecipeInput(
            title: recipe.title,
            description: recipe.description ?? "",
            instructions: recipe.instructions ?? "",
            imageURL: recipe.imageURL ?? RecipeFormModel.fallbackImageURL,
            insulinIndexNotes: recipe.insulinIndexNotes,
            mealTimingSuggestions: recipe.mealTimingSuggestions,
            measurementSystem: recipe.measurementSystem,
            servings: recipe.servings,
            tagIDs: tags.map { $0.id },
            folderID: recipe.folderId,
            isPCOSAdapted: recipe.isPCOSAdapted
        )
    }

    func findIngredientIndex(in list: [Ingredient]? = nil, matching name: String) -> Int? {
        let source = list ?? ingredients
        let trimmedTarget = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedTarget.isEmpty else { return nil }

        // 1. Exact case-insensitive match
        if let idx = source.firstIndex(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedTarget
        }) {
            return idx
        }

        // 2. Substring match
        if let idx = source.firstIndex(where: {
            let n = $0.name.lowercased()
            return n.contains(trimmedTarget) || trimmedTarget.contains(n)
        }) {
            return idx
        }

        return nil
    }

    func applySwap(_ swap: PCOSAnalysisResult.SwapSuggestion) async {
        isApplyingSwap = true
        swapErrorMessage = nil
        swapSuccessMessage = nil

        guard let index = findIngredientIndex(matching: swap.originalIngredient) else {
            swapErrorMessage = "Could not locate \"\(swap.originalIngredient)\" in active ingredients."
            isApplyingSwap = false
            return
        }

        let backupIngredients = ingredients
        let backupRecipe = recipe
        lastAppliedSwapBackup = (swap, backupIngredients, backupRecipe)

        var target = ingredients[index]
        let previousName = target.name
        target.name = swap.suggestedSwap

        if let qtyStr = swap.adjustedQuantity?.trimmingCharacters(in: .whitespacesAndNewlines), !qtyStr.isEmpty {
            target.quantity = qtyStr
            target.quantityValue = IngredientDraft.parseQuantityValue(qtyStr) ?? Double(qtyStr)
        }

        if let unitStr = swap.adjustedUnit?.trimmingCharacters(in: .whitespacesAndNewlines), !unitStr.isEmpty {
            target.unit = unitStr
        }

        ingredients[index] = target
        recipe.isPCOSAdapted = true
        appliedSwapIDs.insert(swap.id)

        do {
            let input = makeRecipeInput()
            let ingredientInputs = ingredients.map {
                IngredientInput(name: $0.name, quantity: $0.quantity, unit: $0.unit, quantityValue: $0.quantityValue)
            }
            try await repository.updateRecipe(id: recipe.id, input: input, ingredients: ingredientInputs)
            swapSuccessMessage = "Replaced \"\(previousName)\" with \"\(swap.suggestedSwap)\""
            isApplyingSwap = false

            pcosService.invalidateCache(for: recipe.id)
            await loadPCOSAnalysis(forceRefresh: true)
        } catch {
            ingredients = backupIngredients
            recipe = backupRecipe
            appliedSwapIDs.remove(swap.id)
            lastAppliedSwapBackup = nil
            swapErrorMessage = "Failed to update recipe: \(error.localizedDescription)"
            isApplyingSwap = false
        }
    }

    func undoSwap() async {
        guard let backup = lastAppliedSwapBackup else { return }
        isApplyingSwap = true
        swapSuccessMessage = nil
        swapErrorMessage = nil

        ingredients = backup.previousIngredients
        recipe = backup.previousRecipe
        appliedSwapIDs.remove(backup.swap.id)
        lastAppliedSwapBackup = nil

        do {
            let input = makeRecipeInput()
            let ingredientInputs = ingredients.map {
                IngredientInput(name: $0.name, quantity: $0.quantity, unit: $0.unit, quantityValue: $0.quantityValue)
            }
            try await repository.updateRecipe(id: recipe.id, input: input, ingredients: ingredientInputs)
            isApplyingSwap = false

            pcosService.invalidateCache(for: recipe.id)
            await loadPCOSAnalysis(forceRefresh: true)
        } catch {
            swapErrorMessage = "Failed to revert swap: \(error.localizedDescription)"
            isApplyingSwap = false
        }
    }

    @discardableResult
    func forkAsPCOSVariation(householdID: UUID) async -> Recipe? {
        isForkingVariation = true
        forkErrorMessage = nil
        forkSuccessMessage = nil

        do {
            let pcosTag = try await tagsRepository.ensurePCOSTag(householdID: householdID)

            let pcosSuffix = " (PCOS-Friendly)"
            let variationTitle: String
            if recipe.title.localizedCaseInsensitiveContains("pcos") {
                variationTitle = recipe.title
            } else {
                variationTitle = "\(recipe.title)\(pcosSuffix)"
            }

            var clonedIngredients = ingredients
            if let analysis = pcosAnalysisState.value {
                for swap in analysis.swaps {
                    if let idx = findIngredientIndex(in: clonedIngredients, matching: swap.originalIngredient) {
                        var ing = clonedIngredients[idx]
                        ing.name = swap.suggestedSwap
                        if let qtyStr = swap.adjustedQuantity?.trimmingCharacters(in: .whitespacesAndNewlines), !qtyStr.isEmpty {
                            ing.quantity = qtyStr
                            ing.quantityValue = IngredientDraft.parseQuantityValue(qtyStr) ?? Double(qtyStr)
                        }
                        if let unitStr = swap.adjustedUnit?.trimmingCharacters(in: .whitespacesAndNewlines), !unitStr.isEmpty {
                            ing.unit = unitStr
                        }
                        clonedIngredients[idx] = ing
                    }
                }
            }

            let ingredientInputs = clonedIngredients.map {
                IngredientInput(name: $0.name, quantity: $0.quantity, unit: $0.unit, quantityValue: $0.quantityValue)
            }

            var tagIDs = Set(tags.map { $0.id })
            tagIDs.insert(pcosTag.id)

            let input = RecipeInput(
                title: variationTitle,
                description: recipe.description ?? "",
                instructions: recipe.instructions ?? "",
                imageURL: recipe.imageURL ?? RecipeFormModel.fallbackImageURL,
                insulinIndexNotes: recipe.insulinIndexNotes,
                mealTimingSuggestions: recipe.mealTimingSuggestions,
                measurementSystem: recipe.measurementSystem,
                servings: recipe.servings,
                tagIDs: Array(tagIDs),
                folderID: recipe.folderId,
                isPCOSAdapted: true
            )

            let newRecipeID = try await repository.createRecipe(input, ingredients: ingredientInputs, householdID: householdID)
            let newRecipe = try await repository.fetchRecipe(id: newRecipeID)

            forkSuccessMessage = "Created PCOS variation: \"\(variationTitle)\""
            isForkingVariation = false
            return newRecipe
        } catch {
            forkErrorMessage = "Failed to save PCOS variation: \(error.localizedDescription)"
            isForkingVariation = false
            return nil
        }
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

