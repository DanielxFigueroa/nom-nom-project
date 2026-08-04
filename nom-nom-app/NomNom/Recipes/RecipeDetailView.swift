import SwiftUI
import MarkdownUI

/// Recipe detail: hero image, tag chips, ingredient checklist with serving scaling,
/// markdown instructions, favorite toggle, owner-only edit (SPEC.md §4).
struct RecipeDetailView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @Environment(\.dismiss) private var dismiss
    @State private var model: RecipeDetailModel
    @State private var showEdit = false
    @State private var showFolderPicker = false

    init(recipe: Recipe) {
        _model = State(initialValue: RecipeDetailModel(recipe: recipe))
    }

    private var isOwner: Bool {
        auth.householdId != nil && model.recipe.householdId == auth.householdId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                VStack(alignment: .leading, spacing: 20) {
                    Text(model.recipe.title)
                        .font(.title.bold())

                    folderSection

                    // Tag chips
                    if !model.tags.isEmpty {
                        tagChipsSection
                    }

                    if let description = model.recipe.description, !description.isEmpty {
                        Text(description)
                            .foregroundStyle(.secondary)
                    }

                    if !model.ingredients.isEmpty {
                        ingredientsSection
                    }

                    if let instructions = model.recipe.instructions, !instructions.isEmpty {
                        section("Instructions") {
                            Markdown(instructions)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(model.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task {
                        await model.toggleFavorite()
                        recipesRefresh.trigger()
                    }
                } label: {
                    Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(model.isFavorite ? Color.nnError : Color.primary)
                }
                .accessibilityLabel(model.isFavorite ? "Unfavorite recipe" : "Favorite recipe")

                if isOwner {
                    Button {
                        showFolderPicker = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("Move to folder")

                    Button {
                        showEdit = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Edit recipe")
                }
            }
        }
        .task { await model.load() }
        .sheet(isPresented: $showFolderPicker) {
            if let householdID = auth.householdId {
                FolderPickerSheet(
                    currentFolderID: model.recipe.folderId,
                    householdID: householdID,
                    onSelectFolder: { folderID in
                        Task {
                            await model.moveToFolder(folderID)
                            recipesRefresh.trigger()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                EditRecipeView(
                    recipe: model.recipe,
                    ingredients: model.ingredients,
                    recipeTags: model.tags,
                    onSaved: {
                        showEdit = false
                        recipesRefresh.trigger()
                        Task { await model.load() }
                    },
                    onDeleted: {
                        showEdit = false
                        recipesRefresh.trigger()
                        dismiss()
                    }
                )
            }
        }
    }

    private var folderSection: some View {
        Button {
            showFolderPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundStyle(Color.nnTint)
                Text(model.currentFolder?.name ?? "Move to folder…")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(model.currentFolder != nil ? Color.primary : Color.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var heroImage: some View {
        CachedAsyncImage(url: imageURL)
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var ingredientsSection: some View {
        section("Ingredients") {
            VStack(alignment: .leading, spacing: 12) {
                servingsStepperHeader

                if model.hasLegacyUnscalableIngredients && model.isServingScaled {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Scaling unavailable for legacy ingredients without numeric quantity.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }

                VStack(spacing: 0) {
                    ForEach(model.ingredients) { ingredient in
                        ingredientRow(ingredient)
                        if ingredient.id != model.ingredients.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var servingsStepperHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Servings")
                    .font(.subheadline.weight(.semibold))
                Text("Serves \(model.desiredServings) · base \(model.recipe.servings)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.isServingScaled {
                Button("Reset") {
                    model.resetServings()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(.nnTint)
                .controlSize(.small)
            }

            Stepper("", value: $model.desiredServings, in: 1...100)
                .labelsHidden()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let checked = model.checkedIDs.contains(ingredient.id)
        let label = model.formattedLabel(for: ingredient)
        return Button {
            model.toggleChecked(ingredient.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(checked ? Color.nnTint : Color.secondary)
                Text(label)
                    .strikethrough(checked)
                    .foregroundStyle(checked ? Color.secondary : Color.primary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(checked ? [.isSelected] : [])
    }

    private var tagChipsSection: some View {
        FlowLayout(spacing: 8) {
            ForEach(model.tags) { tag in
                Text(tag.name)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        tag.isPCOS ? Color.nnTint : Color(.secondarySystemBackground),
                        in: Capsule()
                    )
                    .foregroundStyle(tag.isPCOS ? .white : .primary)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            content()
        }
    }

    private var imageURL: URL? {
        if let raw = model.recipe.imageURL, !raw.isEmpty, let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400")
    }
}
