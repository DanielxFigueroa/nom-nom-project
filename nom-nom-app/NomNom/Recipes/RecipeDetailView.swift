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
        auth.isOwner(of: model.recipe.householdId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                VStack(alignment: .leading, spacing: 20) {
                    Text(model.recipe.title)
                        .font(.title.bold())

                    HStack(spacing: 8) {
                        folderSection

                        if model.recipe.isPCOSAdapted {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.caption2.weight(.bold))
                                Text("Adapted for PCOS")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.nnTint.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.nnTint)
                        }
                    }

                    // Tag chips
                    if !model.tags.isEmpty {
                        tagChipsSection
                    }

                    if let description = model.recipe.description, !description.isEmpty {
                        Text(description)
                            .foregroundStyle(.secondary)
                    }

                    // PCOS Swap & Fork Feedback Banners
                    if let successMsg = model.swapSuccessMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.nnSuccess)
                            Text(successMsg)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Button("Undo") {
                                Task {
                                    await model.undoSwap()
                                    recipesRefresh.trigger()
                                }
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color.nnTint)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.nnSuccess.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let forkMsg = model.forkSuccessMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.nnSuccess)
                            Text(forkMsg)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.nnSuccess.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let errorMsg = model.swapErrorMessage ?? model.forkErrorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(Color.nnError)
                            Text(errorMsg)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.nnError)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.nnError.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if model.isPCOSEnabled {
                        PCOSInsightsCard(model: model)
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
                        await model.exportPDF()
                    }
                } label: {
                    if model.isExportingPDF {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(model.isExportingPDF)
                .accessibilityLabel("Export Recipe as PDF")

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
        .sheet(item: $model.exportedPDF, onDismiss: {
            model.cleanupExportedPDF()
        }) { item in
            ActivityView(activityItems: [item.url]) { _ in
                model.cleanupExportedPDF()
            }
        }
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
        .onChange(of: auth.joinedHouseholdIds) { _, newIDs in
            if !newIDs.contains(model.recipe.householdId) {
                dismiss()
            }
        }
        .onChange(of: model.isPCOSEnabled) { _, isEnabled in
            if isEnabled {
                Task {
                    await model.loadPCOSAnalysis()
                }
            }
        }
        .alert("Reminders Access Required", isPresented: $model.showRemindersPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("NomNom needs access to Reminders to export your ingredients list. You can enable access in Settings.")
        }
        .alert("Export PDF Failed", isPresented: Binding(
            get: { model.pdfErrorMessage != nil },
            set: { if !$0 { model.pdfErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMsg = model.pdfErrorMessage {
                Text(errorMsg)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.swapSuccessMessage)
        .animation(.easeInOut(duration: 0.2), value: model.forkSuccessMessage)
        .animation(.easeInOut(duration: 0.2), value: model.swapErrorMessage)
        .animation(.easeInOut(duration: 0.2), value: model.forkErrorMessage)
        .onChange(of: model.forkSuccessMessage) { _, newMsg in
            if newMsg != nil {
                recipesRefresh.trigger()
            }
        }
    }

    @ViewBuilder
    private var folderSection: some View {
        if let currentFolder = model.currentFolder {
            if isOwner {
                Button {
                    showFolderPicker = true
                } label: {
                    folderBadge(name: currentFolder.name, showChevron: true, isPlaceholder: false)
                }
                .buttonStyle(.plain)
            } else {
                folderBadge(name: currentFolder.name, showChevron: false, isPlaceholder: false)
            }
        } else if isOwner {
            Button {
                showFolderPicker = true
            } label: {
                folderBadge(name: "Move to folder…", showChevron: true, isPlaceholder: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func folderBadge(name: String, showChevron: Bool, isPlaceholder: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.caption)
                .foregroundStyle(Color.nnTint)
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(isPlaceholder ? Color.secondary : Color.primary)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private var heroImage: some View {
        CachedAsyncImage(url: imageURL)
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Ingredients")
                    .font(.title3.bold())
                Spacer()
                remindersExportButton
            }

            if let successMessage = model.exportSuccessMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.nnSuccess)
                    Text(successMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.nnSuccess.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let errorMessage = model.remindersErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.nnError)
                    Text(errorMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.nnError)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.nnError.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            servingsSliderHeader

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
        .animation(.easeInOut(duration: 0.2), value: model.exportSuccessMessage)
        .animation(.easeInOut(duration: 0.2), value: model.remindersErrorMessage)
    }

    @ViewBuilder
    private var remindersExportButton: some View {
        if model.isExportingToReminders {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Exporting…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground), in: Capsule())
        } else {
            Menu {
                Section("Export") {
                    if model.hasCheckedIngredients {
                        Button {
                            Task {
                                await model.exportToReminders(onlyUnchecked: true)
                            }
                        } label: {
                            Label("Export Unchecked (\(model.uncheckedIngredients.count))", systemImage: "checklist.unchecked")
                        }
                    }

                    Button {
                        Task {
                            await model.exportToReminders(onlyUnchecked: false)
                        }
                    } label: {
                        Label(model.hasCheckedIngredients ? "Export All (\(model.ingredients.count))" : "Export Ingredients", systemImage: "checklist")
                    }
                }

                if !model.availableReminderLists.isEmpty {
                    Section("Destination List") {
                        ForEach(model.availableReminderLists) { list in
                            Button {
                                model.selectPreferredList(list.id)
                            } label: {
                                if model.selectedListID == list.id {
                                    Label(list.title, systemImage: "checkmark")
                                } else {
                                    Text(list.title)
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.nnTint)
                    Text(remindersButtonTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.nnTint)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
    }

    private var remindersButtonTitle: String {
        if let name = model.selectedListName, !name.isEmpty, name != "Reminders" {
            let truncated = name.count > 16 ? String(name.prefix(13)) + "…" : name
            return "Add to \(truncated)"
        }
        return "Add to Reminders"
    }

    private var servingsSliderHeader: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Servings")
                        .font(.subheadline.weight(.semibold))
                    Text("Serves \(model.desiredServings) · base \(model.recipe.servings)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                Spacer()

                if model.isServingScaled {
                    Button("Reset") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.resetServings()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.nnTint)
                    .controlSize(.small)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        model.decrementServings()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(model.desiredServings > model.minServings ? Color.nnTint : Color(.tertiaryLabel))
                }
                .disabled(model.desiredServings <= model.minServings)
                .accessibilityLabel("Decrease servings")

                Slider(
                    value: Binding(
                        get: { model.desiredServingsDouble },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                model.desiredServingsDouble = newValue
                            }
                        }
                    ),
                    in: Double(model.minServings)...Double(model.maxServings),
                    step: 1
                )
                .tint(.nnTint)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        model.incrementServings()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(model.desiredServings < model.maxServings ? Color.nnTint : Color(.tertiaryLabel))
                }
                .disabled(model.desiredServings >= model.maxServings)
                .accessibilityLabel("Increase servings")
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .sensoryFeedback(.selection, trigger: model.desiredServings)
        .animation(.easeInOut(duration: 0.2), value: model.isServingScaled)
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
                    .animation(.easeInOut(duration: 0.15), value: label)
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
