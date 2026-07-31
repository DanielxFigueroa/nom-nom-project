import SwiftUI

/// Edit recipe + delete danger zone (SPEC.md §4). Presented as a sheet from the
/// detail screen. Ports RN `app/edit-recipe.tsx`.
struct EditRecipeView: View {
    let recipe: Recipe
    var onSaved: () -> Void
    var onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var model: RecipeFormModel
    @State private var isSubmitting = false
    @State private var isDeleting = false
    @State private var showDeleteConfirm = false

    private let repository = RecipesRepository()

    init(recipe: Recipe, ingredients: [Ingredient], onSaved: @escaping () -> Void, onDeleted: @escaping () -> Void) {
        self.recipe = recipe
        self.onSaved = onSaved
        self.onDeleted = onDeleted
        _model = State(initialValue: RecipeFormModel(recipe: recipe, ingredients: ingredients))
    }

    var body: some View {
        VStack(spacing: 0) {
            RecipeFormView(
                model: model,
                submitTitle: "Update Recipe",
                isSubmitting: isSubmitting,
                onSubmit: update
            )
            dangerZone
        }
        .navigationTitle("Edit Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .confirmationDialog(
            "Delete \"\(recipe.title)\"? This cannot be undone.",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { Task { await deleteRecipe() } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var dangerZone: some View {
        VStack(spacing: 8) {
            Text("DANGER ZONE")
                .font(.caption.bold())
                .foregroundStyle(Color.nnError)
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                if isDeleting {
                    ProgressView().tint(.white)
                } else {
                    Label("Delete Recipe", systemImage: "trash.fill").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.nnError)
            .disabled(isDeleting || isSubmitting)
        }
        .padding(16)
    }

    private func update(_ input: RecipeInput, _ ingredients: [IngredientInput]) async {
        isSubmitting = true
        do {
            try await repository.updateRecipe(id: recipe.id, input: input, ingredients: ingredients)
            onSaved()
        } catch {
            model.errorMessage = "Failed to update recipe:\n\(describeError(error))"
        }
        isSubmitting = false
    }

    private func deleteRecipe() async {
        isDeleting = true
        do {
            try await repository.deleteRecipe(id: recipe.id)
            onDeleted()
        } catch {
            model.errorMessage = "Failed to delete recipe:\n\(describeError(error))"
        }
        isDeleting = false
    }
}
