import SwiftUI
import PhotosUI
import UIKit
import MarkdownUI

/// Shared 3-step recipe form UI used by Add and Edit (SPEC.md §4).
struct RecipeFormView: View {
    @Bindable var model: RecipeFormModel
    var submitTitle: String
    var isSubmitting: Bool
    var onSubmit: (RecipeInput, [IngredientInput]) async -> Void

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
            ScrollView {
                Group {
                    switch model.step {
                    case .details: detailsStep
                    case .ingredients: ingredientsStep
                    case .instructions: instructionsStep
                    }
                }
                .padding(20)
            }
            footer
        }
        .alert("Please fix the following", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }

    // MARK: Progress

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(stepTitle).font(.headline)
                Spacer()
                Text("Step \(model.step.rawValue) of 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(model.step.rawValue), total: 3)
                .tint(.nnTint)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var stepTitle: String {
        switch model.step {
        case .details: return "Recipe Details"
        case .ingredients: return "Ingredients List"
        case .instructions: return "Cooking Instructions"
        }
    }

    // MARK: Step 1 — Details

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            labeledField("Recipe Title *") {
                TextField("Enter recipe title...", text: $model.title)
                    .textFieldStyle(.roundedBorder)
            }
            labeledField("Description") {
                TextField("Describe your recipe briefly...", text: $model.descriptionText, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            }
            labeledField("Insulin Index Notes (Optional)") {
                TextField("Notes on glycemic & insulin impact...", text: $model.insulinIndexNotes, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }
            labeledField("Meal Timing Suggestions (Optional)") {
                TextField("Best time to eat (e.g., post-workout)...", text: $model.mealTimingSuggestions, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }
            labeledField("Cover Image") {
                imagePicker
            }
        }
    }

    private var imagePicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(Color.secondary)
                    .frame(height: 180)

                if model.isUploading {
                    ProgressView()
                } else if let picked = model.pickedImage {
                    picked.resizable().scaledToFill()
                        .frame(height: 180).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay { changeImageOverlay }
                } else if let urlString = model.imageURLString, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 180).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay { changeImageOverlay }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus").font(.largeTitle).foregroundStyle(Color.nnTint)
                        Text("Select a recipe image").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadPickedImage(newItem) }
        }
    }

    private var changeImageOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
            Label("Change Image", systemImage: "camera.fill")
                .foregroundStyle(.white)
                .font(.subheadline.bold())
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadPickedImage(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        let isPNG = data.starts(with: [0x89, 0x50, 0x4E, 0x47])
        await model.uploadImage(data: data, preview: Image(uiImage: uiImage), isPNG: isPNG)
    }

    // MARK: Step 2 — Ingredients

    private var ingredientsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add ingredients for your recipe. Select quantities and units based on your preferred system.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Measurement System").font(.subheadline.bold())
                    Spacer()
                }
                Picker("System", selection: $model.measurementSystem) {
                    ForEach(MeasurementSystem.allCases) { sys in
                        Text(sys.displayName).tag(sys)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: model.measurementSystem) { _, newSystem in
                    if let currentUnit = model.ingUnit, !RecipeUnit.options(for: newSystem).contains(currentUnit) {
                        model.ingUnit = nil
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 12) {
                Text("Add Ingredient").font(.subheadline.bold())
                HStack(spacing: 8) {
                    Picker("Qty", selection: $model.ingQtyOption) {
                        Text("Qty").tag(Optional<QtyOption>.none)
                        ForEach(QtyOption.all) { option in
                            Text(option.label).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(height: 36)
                    .padding(.horizontal, 8)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))

                    Picker("Unit", selection: $model.ingUnit) {
                        Text("Unit").tag(Optional<RecipeUnit>.none)
                        ForEach(RecipeUnit.options(for: model.measurementSystem)) { unit in
                            Text(unit.displayName).tag(Optional(unit))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                    .frame(height: 36)
                    .padding(.horizontal, 8)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))

                    TextField("Name (e.g. Chicken)", text: $model.ingName)
                        .textFieldStyle(.roundedBorder)
                }

                if model.isSeafood(model.ingName) {
                    warning("PCOS Health Warning: Seafood requires dietary substitution. Consider organic chicken, turkey, or tofu.")
                }

                Button {
                    model.addIngredient()
                } label: {
                    Label("Add to List", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnTint)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            Text("Ingredients List (\(model.ingredients.count))").font(.subheadline.bold())
            if model.ingredients.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "basket").font(.largeTitle).foregroundStyle(.secondary)
                    Text("No ingredients added yet.").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(model.ingredients) { ingredient in
                    ingredientRow(ingredient)
                }
            }
        }
    }

    private func ingredientRow(_ ingredient: IngredientDraft) -> some View {
        let hasWarning = model.isSeafood(ingredient.name)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.displayLabel)
                if hasWarning {
                    Text("⚠️ Substitution needed")
                        .font(.caption).foregroundStyle(Color.nnWarning)
                }
            }
            Spacer()
            Button {
                model.removeIngredient(ingredient)
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.nnError)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            if hasWarning {
                RoundedRectangle(cornerRadius: 8).strokeBorder(Color.nnWarning)
            }
        }
    }

    // MARK: Step 3 — Instructions

    private var instructionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $model.showMarkdownPreview) {
                Text("Write Instructions").tag(false)
                Text("Markdown Preview").tag(true)
            }
            .pickerStyle(.segmented)

            if model.showMarkdownPreview {
                Group {
                    if model.instructions.trimmed.isEmpty {
                        Text("Instructions preview will appear here.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 250, alignment: .top)
                    } else {
                        Markdown(model.instructions)
                            .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            } else {
                labeledField("Instructions (Markdown supported) *") {
                    TextEditor(text: $model.instructions)
                        .frame(minHeight: 250)
                        .padding(8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).strokeBorder(Color(.separator))
                        }
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if model.step != .details {
                Button("Back") { model.goBack() }
                    .buttonStyle(.bordered)
                    .tint(.nnTint)
                    .disabled(isSubmitting)
            }
            Spacer()
            if model.step != .instructions {
                Button("Next") { model.goNext() }
                    .buttonStyle(.borderedProminent)
                    .tint(.nnTint)
            } else {
                Button {
                    guard let (input, ingredients) = model.buildPayload() else { return }
                    Task { await onSubmit(input, ingredients) }
                } label: {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(submitTitle)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnTint)
                .disabled(isSubmitting)
            }
        }
        .padding(16)
        .background(.bar)
    }

    // MARK: Helpers

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.semibold))
            content()
        }
    }

    private func warning(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.nnWarning)
            Text(text).font(.footnote).foregroundStyle(Color.nnWarning)
        }
        .padding(10)
        .background(Color.nnWarning.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }
}
