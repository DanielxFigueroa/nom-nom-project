import SwiftUI

/// Add Recipe tab: 3-step create form (SPEC.md §4). Ports RN `(tabs)/add-recipe.tsx`.
struct AddRecipeView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @State private var model = RecipeFormModel()
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private let repository = RecipesRepository()

    var body: some View {
        NavigationStack {
            RecipeFormView(
                model: model,
                submitTitle: "Create Recipe",
                isSubmitting: isSubmitting,
                onSubmit: create
            )
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { model = RecipeFormModel() } // reset for the next recipe
            } message: {
                Text("Recipe added successfully!")
            }
        }
    }

    private func create(_ input: RecipeInput, _ ingredients: [IngredientInput]) async {
        guard let householdID = auth.householdId else {
            model.errorMessage = "You must join a household before adding recipes."
            return
        }
        isSubmitting = true
        do {
            try await repository.createRecipe(input, ingredients: ingredients, householdID: householdID)
            recipesRefresh.trigger()
            showSuccess = true
        } catch {
            model.errorMessage = "Failed to save recipe:\n\(describeError(error))"
        }
        isSubmitting = false
    }
}
