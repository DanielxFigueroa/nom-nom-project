import SwiftUI

/// Recipe detail: image, ingredient checklist, markdown instructions, PCOS cards,
/// favorite toggle, owner-only edit (SPEC.md §4). Implemented in Milestone 2.
struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScaffoldPlaceholder(
            title: recipe.title,
            specNote: "Milestone 2: hero image; ingredient checklist (local); markdown instructions; PCOS cards; favorite via toggle_recipe_favorite RPC; owner Edit."
        )
    }
}
