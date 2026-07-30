import SwiftUI

/// Add Recipe: 3-step create form (SPEC.md §4). Implemented in Milestone 2.
struct AddRecipeView: View {
    var body: some View {
        NavigationStack {
            ScaffoldPlaceholder(
                title: "Add Recipe",
                specNote: "Milestone 2: 3-step form (Details → Ingredients → Instructions); PhotosPicker upload; PCOS fields; seafood warning."
            )
            .navigationTitle("Add Recipe")
        }
    }
}
