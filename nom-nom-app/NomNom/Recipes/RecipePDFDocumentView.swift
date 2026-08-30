import SwiftUI
import UIKit

/// A dedicated, print-optimized view for rendering recipes to PDF.
struct RecipePDFDocumentView: View {
    let recipe: Recipe
    let ingredients: [Ingredient]
    let tags: [Tag]
    let desiredServings: Int
    let scaleFactor: Double
    let headerImage: UIImage?
    let pageWidth: CGFloat
    let exportDate: Date

    init(
        recipe: Recipe,
        ingredients: [Ingredient],
        tags: [Tag],
        desiredServings: Int,
        scaleFactor: Double,
        headerImage: UIImage?,
        pageWidth: CGFloat = 612,
        exportDate: Date = Date()
    ) {
        self.recipe = recipe
        self.ingredients = ingredients
        self.tags = tags
        self.desiredServings = desiredServings
        self.scaleFactor = scaleFactor
        self.headerImage = headerImage
        self.pageWidth = pageWidth
        self.exportDate = exportDate
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerBranding

            recipeTitleAndDescription

            metadataSection

            if let headerImage {
                Image(uiImage: headerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(white: 0.85), lineWidth: 1)
                    )
            }

            Divider()
                .background(Color(white: 0.8))

            // Ingredients and Instructions
            VStack(alignment: .leading, spacing: 24) {
                if !ingredients.isEmpty {
                    ingredientsSection
                }

                if let instructions = recipe.instructions, !instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    instructionsSection(instructions)
                }
            }

            Spacer(minLength: 20)

            footerBranding
        }
        .padding(36)
        .frame(width: pageWidth)
        .background(Color.white)
        .foregroundStyle(Color(white: 0.12))
    }

    // MARK: - Header Branding

    private var headerBranding: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.nnTint)
                Text("NOM NOM RECIPES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.nnTint)
            }
            Spacer()
            Text("Exported \(dateFormatter.string(from: exportDate))")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color(white: 0.45))
        }
        .padding(.bottom, 4)
    }

    // MARK: - Title & Description

    private var recipeTitleAndDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color(white: 0.08))
                .fixedSize(horizontal: false, vertical: true)

            if let description = recipe.description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.35))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Metadata Badges

    private var metadataSection: some View {
        FlowLayout(spacing: 8) {
            // Servings badge
            metadataPill(
                icon: "person.2.fill",
                label: desiredServings == recipe.servings
                    ? "Serves \(desiredServings)"
                    : "Serves \(desiredServings) (Base: \(recipe.servings))"
            )

            // Measurement system badge
            metadataPill(
                icon: "scalemass.fill",
                label: recipe.measurementSystem == .imperial ? "Imperial Units" : "Metric Units"
            )

            // Ingredient count badge
            metadataPill(
                icon: "list.bullet",
                label: "\(ingredients.count) \(ingredients.count == 1 ? "ingredient" : "ingredients")"
            )

            // Tags / PCOS
            ForEach(tags) { tag in
                if tag.isPCOS {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(tag.name)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.nnTint.opacity(0.15))
                    .foregroundStyle(Color.nnTint)
                    .clipShape(Capsule())
                } else {
                    Text(tag.name)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.93))
                        .foregroundStyle(Color(white: 0.25))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func metadataPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(white: 0.4))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(white: 0.25))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(white: 0.93))
        .clipShape(Capsule())
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Ingredients")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.1))
                if desiredServings != recipe.servings {
                    Text("(Scaled for \(desiredServings) servings)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.nnTint)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(ingredients) { ingredient in
                    let label = formattedIngredientLabel(ingredient)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "square")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.5))
                            .padding(.top, 2)
                        Text(label)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(white: 0.15))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func formattedIngredientLabel(_ ingredient: Ingredient) -> String {
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

    // MARK: - Instructions Section

    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Instructions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(white: 0.1))

            let steps = parseInstructionSteps(instructions)
            if steps.count > 1 {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.white)
                                .frame(width: 20, height: 20)
                                .background(Color.nnTint, in: Circle())
                                .padding(.top, 1)

                            if let attr = try? AttributedString(markdown: step) {
                                Text(attr)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(white: 0.15))
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text(step)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(white: 0.15))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else {
                if let attr = try? AttributedString(markdown: instructions) {
                    Text(attr)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.15))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(instructions)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.15))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func parseInstructionSteps(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var result: [String] = []
        for line in lines {
            // Strip markdown numbered prefixes like "1. ", "2. ", etc. or bullets "- "
            if let match = line.range(of: #"^(\d+[\.\)]|\-|\*)\s+"#, options: .regularExpression) {
                let step = String(line[match.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !step.isEmpty {
                    result.append(step)
                }
            } else {
                result.append(line)
            }
        }
        return result.isEmpty ? [text] : result
    }

    // MARK: - Footer

    private var footerBranding: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color(white: 0.85))
            HStack {
                Text("NomNom — Delicious home-cooked recipes made simple.")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(Color(white: 0.5))
                Spacer()
                Text("Page 1 of 1")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))
            }
        }
    }
}
