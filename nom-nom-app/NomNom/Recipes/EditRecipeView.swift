import SwiftUI

/// Edit recipe + delete danger zone (SPEC.md §4). Implemented in Milestone 2.
struct EditRecipeView: View {
    let recipe: Recipe

    var body: some View {
        ScaffoldPlaceholder(
            title: "Edit \(recipe.title)",
            specNote: "Milestone 2: pre-filled 3-step form; update recipe + replace ingredients; delete danger zone with confirmation."
        )
    }
}
