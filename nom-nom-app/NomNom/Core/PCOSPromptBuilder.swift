import Foundation

/// Constructs evidence-based, compassionate clinical prompts for PCOS dietary analysis.
struct PCOSPromptBuilder: Sendable {

    /// Generates the system prompt embedding clinical principles, non-restrictive tone, and JSON schema constraints.
    static func buildSystemPrompt(settings: PCOSSettings) -> String {
        var focusDescriptions: [String] = []

        if settings.focusAreas.contains(.insulinResistance) {
            focusDescriptions.append("- Insulin Resistance: Focus on low glycemic load, blood sugar buffering with dietary fiber/protein/fats, and meal sequencing (eating greens and protein before simple carbohydrates).")
        }
        if settings.focusAreas.contains(.inflammation) {
            focusDescriptions.append("- Anti-Inflammatory: Emphasize omega-3 fatty acids, colorful polyphenols, antioxidant herbs/spices (e.g., turmeric, ginger, cinnamon), and minimizing pro-inflammatory ultra-processed oils.")
        }
        if settings.focusAreas.contains(.highProtein) {
            focusDescriptions.append("- High Protein: Optimize protein density (aiming for 25-35g per meal) to stabilize ghrelin, promote metabolic satiety, and preserve lean muscle mass.")
        }
        if settings.focusAreas.contains(.dairySensitivity) {
            focusDescriptions.append("- Dairy Sensitivity: Suggest nourishing, non-dairy plant-based substitutes (e.g., unsweetened almond/coconut milk, cashew cream, nutritional yeast) while preserving micronutrient balance.")
        }
        if settings.focusAreas.contains(.glutenSensitivity) {
            focusDescriptions.append("- Gluten Sensitivity: Identify wheat/gluten ingredients and suggest wholesome gluten-free whole grain substitutes (e.g., quinoa, certified GF oats, buckwheat, almond flour).")
        }

        let focusText = focusDescriptions.isEmpty
            ? "- General PCOS Wellness: Emphasize balanced blood sugar, hormone equilibrium, and nutrient-dense whole foods."
            : focusDescriptions.joined(separator: "\n")

        let styleInstruction: String
        switch settings.suggestionStyle {
        case .gentleAdditions:
            styleInstruction = """
            SUGGESTION PHILOSOPHY — "ADD BEFORE YOU SUBTRACT":
            Do not eliminate or forbid foods. Instead, recommend nutrient-dense additions (such as stirring in chia/hemp seeds, adding extra leafy greens, or pairing carbs with healthy fats and lean proteins) that soften glucose spikes while keeping meals satisfying.
            """
        case .directSwaps:
            styleInstruction = """
            SUGGESTION PHILOSOPHY — DIRECT SWAPS:
            Provide clear 1-to-1 ingredient replacements for high-glycemic or sensitivity-triggering items, with realistic replacement quantities and units, while maintaining recipe texture and taste.
            """
        }

        return """
        You are NomNom's on-device clinical PCOS Nutrition Assistant.
        Your tone is compassionate, supportive, and non-restrictive. You avoid diet culture, shame, and unnecessary food elimination.

        USER FOCUS AREAS:
        \(focusText)

        \(styleInstruction)

        ANALYSIS OUTPUT REQUIREMENTS:
        Respond strictly with a single valid JSON object. Do not include markdown code block formatting, backticks, or conversational text outside the JSON.
        The JSON structure MUST adhere to this exact schema:
        {
          "summary_note": "A concise, supportive overview (1-2 sentences) of how this recipe supports the user's hormone and blood sugar goals.",
          "glycemic_impact_badge": "Blood Sugar Balanced" | "Moderate Glycemic" | "High Glycemic Impact",
          "swaps": [
            {
              "original_ingredient": "Ingredient name as written in recipe",
              "suggested_swap": "Recommended replacement or addition",
              "rationale": "Clear, gentle clinical reason (e.g., lowers glycemic load, adds omega-3s)",
              "adjusted_quantity": "Suggested quantity string or null",
              "adjusted_unit": "Suggested unit string or null"
            }
          ],
          "pairing_tips": [
            "Actionable pairing tip (e.g., eat fiber first, add apple cider vinegar dressing, 10-minute post-meal walk)"
          ],
          "positive_highlights": [
            "Positive highlight celebrating a nutrient already in the recipe"
          ]
        }
        """
    }

    /// Generates the user input prompt containing recipe details, ingredients, and instructions.
    static func buildUserPrompt(
        recipe: Recipe,
        ingredients: [Ingredient]
    ) -> String {
        var ingredientLines: [String] = []
        for ing in ingredients {
            var parts: [String] = []
            if let qty = ing.quantity, !qty.trimmingCharacters(in: .whitespaces).isEmpty {
                parts.append(qty)
            }
            if let unit = ing.unit, !unit.trimmingCharacters(in: .whitespaces).isEmpty {
                parts.append(unit)
            }
            parts.append(ing.name)
            ingredientLines.append("- " + parts.joined(separator: " "))
        }

        let ingredientsText = ingredientLines.isEmpty
            ? "None specified"
            : ingredientLines.joined(separator: "\n")

        let instructionsText = recipe.instructions?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? recipe.instructions!
            : "None specified"

        return """
        Please analyze this recipe for PCOS nutrition:

        Title: \(recipe.title)
        Servings: \(recipe.servings)

        Ingredients:
        \(ingredientsText)

        Instructions:
        \(instructionsText)
        """
    }
}
