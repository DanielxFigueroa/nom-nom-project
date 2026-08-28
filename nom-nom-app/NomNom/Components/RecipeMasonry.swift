import SwiftUI

/// Two-column masonry grid of recipe cards with staggered heights, mirroring the
/// RN `RecipeList` layout. Tapping a card pushes the recipe detail.
///
/// Cards are keyed by the recipe's stable `id` (not the array index) so inserting
/// a new recipe at the top doesn't reshuffle view identities — which would
/// otherwise mismatch images and tap targets to the wrong rows.
struct RecipeMasonry: View {
    let recipes: [Recipe]

    private let spacing: CGFloat = 8

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: spacing) {
                column(for: leftItems)
                column(for: rightItems)
            }
            .padding(spacing)
        }
    }

    private var enumeratedRecipes: [(index: Int, recipe: Recipe)] {
        recipes.enumerated().map { (index: $0.offset, recipe: $0.element) }
    }

    private var leftItems: [(index: Int, recipe: Recipe)] {
        enumeratedRecipes.filter { $0.index % 2 == 0 }
    }

    private var rightItems: [(index: Int, recipe: Recipe)] {
        enumeratedRecipes.filter { $0.index % 2 != 0 }
    }

    private func column(for items: [(index: Int, recipe: Recipe)]) -> some View {
        VStack(spacing: spacing) {
            ForEach(items, id: \.recipe.id) { item in
                NavigationLink {
                    RecipeDetailView(recipe: item.recipe)
                } label: {
                    RecipeCard(recipe: item.recipe, height: cardHeight(at: item.index))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Staggered heights matching RN's index-based pattern (250 / 200 / 300).
    private func cardHeight(at index: Int) -> CGFloat {
        if index % 3 == 0 { return 250 }
        if index % 2 == 0 { return 200 }
        return 300
    }
}
