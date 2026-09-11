import Foundation

/// Fast, deterministic, on-device clinical heuristic analyzer for PCOS nutrition.
/// Acts as an offline fallback when on-device LLM inference is pending or unavailable.
struct PCOSHeuristicAnalyzer: Sendable {

    init() {}

    func analyze(
        recipe: Recipe,
        ingredients: [Ingredient],
        settings: PCOSSettings
    ) -> PCOSAnalysisResult {
        let normalizedIngredients = ingredients.map { ing in
            (name: ing.name.lowercased(), original: ing)
        }

        // 1. Evaluate Glycemic Impact & Balancing Elements
        var hasRefinedSugar = false
        var hasRefinedCarbs = false
        var hasBalancingProtein = false
        var hasBalancingFiber = false
        var hasBalancingFat = false

        let refinedSugars = ["sugar", "corn syrup", "cane sugar", "powdered sugar", "brown sugar", "agave", "honey", "maple syrup", "molasses"]
        let refinedCarbs = ["white flour", "all-purpose flour", "ap flour", "white rice", "jasmine rice", "white bread", "pasta", "potato", "potatoes", "french fries", "cornstarch", "noodles"]
        let proteinSources = ["chicken", "turkey", "beef", "salmon", "tuna", "egg", "eggs", "tofu", "tempeh", "edamame", "greek yogurt", "lentils", "beans", "chickpeas", "cottage cheese", "protein powder", "shrimp", "fish", "pork"]
        let fiberSources = ["spinach", "kale", "broccoli", "cauliflower", "chia", "flax", "avocado", "berries", "blueberry", "raspberry", "strawberry", "cabbage", "brussels", "zucchini", "asparagus", "arugula", "hemp seeds", "pumpkin seeds", "chia seeds"]
        let healthyFats = ["olive oil", "avocado oil", "avocado", "walnuts", "almonds", "pumpkin seeds", "hemp seeds", "chia seeds", "flaxseed", "ghee"]

        for item in normalizedIngredients {
            if refinedSugars.contains(where: { item.name.contains($0) }) {
                hasRefinedSugar = true
            }
            if refinedCarbs.contains(where: { item.name.contains($0) }) {
                hasRefinedCarbs = true
            }
            if proteinSources.contains(where: { item.name.contains($0) }) {
                hasBalancingProtein = true
            }
            if fiberSources.contains(where: { item.name.contains($0) }) {
                hasBalancingFiber = true
            }
            if healthyFats.contains(where: { item.name.contains($0) }) {
                hasBalancingFat = true
            }
        }

        let glycemicImpactBadge: String
        if hasRefinedSugar && !hasBalancingProtein && !hasBalancingFiber && !hasBalancingFat {
            glycemicImpactBadge = "High Glycemic Impact"
        } else if (hasRefinedCarbs || hasRefinedSugar) && (!hasBalancingProtein || (!hasBalancingFiber && !hasBalancingFat)) {
            glycemicImpactBadge = "Moderate Glycemic"
        } else {
            glycemicImpactBadge = "Blood Sugar Balanced"
        }

        // 2. Generate Nuanced Swaps & Additions
        var swaps: [PCOSAnalysisResult.SwapSuggestion] = []
        let isGentle = (settings.suggestionStyle == .gentleAdditions)

        for item in normalizedIngredients {
            let name = item.name
            let origName = item.original.name

            // Insulin Resistance / Refined Carbs & Sugars
            if settings.focusAreas.contains(.insulinResistance) || settings.focusAreas.isEmpty {
                if name.contains("white rice") || name.contains("jasmine rice") {
                    if isGentle {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Pair with 2 tbsp Hemp Seeds or 1 cup Cauliflower Rice blend",
                            rationale: "Adds fiber and protein to buffer starch absorption without sacrificing your favorite rice.",
                            adjustedQuantity: "2",
                            adjustedUnit: "tbsp"
                        ))
                    } else {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Quinoa or Cauliflower Rice Blend",
                            rationale: "Significantly lowers glycemic load and boosts metabolic micronutrients.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    }
                } else if name.contains("all-purpose flour") || name.contains("white flour") {
                    if isGentle {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Blend 50/50 with Almond Flour or Ground Flaxseed",
                            rationale: "Introduces fiber and healthy fats to slow glucose release.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    } else {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Almond Flour or 1:1 Gluten-Free Oat Flour",
                            rationale: "Low carb and rich in dietary fiber to keep insulin response smooth.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    }
                } else if name.contains("sugar") && !name.contains("coconut sugar") {
                    if isGentle {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Reduce amount by 30% and add 1/2 tsp Ceylon Cinnamon",
                            rationale: "Ceylon cinnamon enhances insulin receptor sensitivity while preserving flavor.",
                            adjustedQuantity: "1/2",
                            adjustedUnit: "tsp"
                        ))
                    } else {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Monk Fruit Sweetener or Allulose",
                            rationale: "Zero-glycemic natural sweetener that prevents blood sugar and insulin spikes.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    }
                } else if name == "pasta" || name.contains("white pasta") || name.contains("spaghetti") {
                    if isGentle {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Toss with 1 cup Zucchini Noodles or Broccoli Florets",
                            rationale: "Increases meal volume and fiber density for prolonged satiety.",
                            adjustedQuantity: "1",
                            adjustedUnit: "cup"
                        ))
                    } else {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "Chickpea Pasta or Edamame Noodles",
                            rationale: "Delivers triple the dietary fiber and 20g+ plant protein per serving.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    }
                }
            }

            // Dairy Sensitivity
            if settings.focusAreas.contains(.dairySensitivity) {
                if name.contains("heavy cream") || name.contains("whole milk") || name.contains("cow milk") || name == "milk" {
                    swaps.append(.init(
                        originalIngredient: origName,
                        suggestedSwap: "Full-Fat Coconut Milk or Unsweetened Almond Milk",
                        rationale: "Creamy, dairy-free alternative that supports digestive calm and hormonal balance.",
                        adjustedQuantity: item.original.quantity,
                        adjustedUnit: item.original.unit
                    ))
                } else if name == "butter" {
                    swaps.append(.init(
                        originalIngredient: origName,
                        suggestedSwap: "Ghee (Clarified Butter) or Extra Virgin Olive Oil",
                        rationale: "Ghee is virtually lactose and casein-free, while olive oil delivers anti-inflammatory polyphenols.",
                        adjustedQuantity: item.original.quantity,
                        adjustedUnit: item.original.unit
                    ))
                } else if name.contains("cheese") || name.contains("parmesan") {
                    swaps.append(.init(
                        originalIngredient: origName,
                        suggestedSwap: "Nutritional Yeast or Cashew Parmesan",
                        rationale: "Delivers a savory umami finish rich in B-vitamins without dairy sensitivities.",
                        adjustedQuantity: item.original.quantity,
                        adjustedUnit: item.original.unit
                    ))
                }
            }

            // Gluten Sensitivity
            if settings.focusAreas.contains(.glutenSensitivity) {
                if (name.contains("flour") && !name.contains("almond") && !name.contains("coconut") && !name.contains("gluten-free")) {
                    if !swaps.contains(where: { $0.originalIngredient == origName }) {
                        swaps.append(.init(
                            originalIngredient: origName,
                            suggestedSwap: "1:1 Gluten-Free Baking Blend or Almond Flour",
                            rationale: "Gentle on the gut lining, eliminating inflammatory gluten peptides.",
                            adjustedQuantity: item.original.quantity,
                            adjustedUnit: item.original.unit
                        ))
                    }
                } else if name.contains("soy sauce") {
                    swaps.append(.init(
                        originalIngredient: origName,
                        suggestedSwap: "Coconut Aminos or Tamari (Gluten-Free)",
                        rationale: "Gluten-free savory depth with lower sodium impact.",
                        adjustedQuantity: item.original.quantity,
                        adjustedUnit: item.original.unit
                    ))
                }
            }

            // Inflammation (Oils)
            if settings.focusAreas.contains(.inflammation) {
                if name.contains("canola oil") || name.contains("vegetable oil") || name.contains("soybean oil") || name.contains("corn oil") {
                    swaps.append(.init(
                        originalIngredient: origName,
                        suggestedSwap: "Extra Virgin Olive Oil or Avocado Oil",
                        rationale: "High in monounsaturated fats and antioxidants, replacing pro-inflammatory refined seed oils.",
                        adjustedQuantity: item.original.quantity,
                        adjustedUnit: item.original.unit
                    ))
                }
            }
        }

        // High protein check
        if settings.focusAreas.contains(.highProtein) && !hasBalancingProtein {
            swaps.append(.init(
                originalIngredient: "Meal Protein Base",
                suggestedSwap: "Add 3 tbsp Hemp Hearts, 2 Eggs, or 4oz Grilled Chicken / Tofu",
                rationale: "Aim for 25-35g protein to optimize peptide YY and ghrelin satiety hormones.",
                adjustedQuantity: "3",
                adjustedUnit: "tbsp"
            ))
        }

        // 3. Positive Highlights from Existing Ingredients
        var positiveHighlights: [String] = []
        for item in normalizedIngredients {
            let name = item.name
            if (name.contains("chia") || name.contains("flax") || name.contains("hemp")) && !positiveHighlights.contains(where: { $0.contains("seeds") }) {
                positiveHighlights.append("Seeds provide plant-based omega-3s and lignans to support estrogen metabolism.")
            }
            if (name.contains("avocado") || name.contains("olive oil")) && !positiveHighlights.contains(where: { $0.contains("Monounsaturated") }) {
                positiveHighlights.append("Monounsaturated fats help stabilize post-meal glucose and promote hormone production.")
            }
            if (name.contains("spinach") || name.contains("kale") || name.contains("broccoli") || name.contains("cabbage")) && !positiveHighlights.contains(where: { $0.contains("cruciferous") }) {
                positiveHighlights.append("Greens and cruciferous veggies supply DIM and folate for liver detoxification.")
            }
            if (name.contains("salmon") || name.contains("sardine") || name.contains("tuna")) && !positiveHighlights.contains(where: { $0.contains("omega-3") }) {
                positiveHighlights.append("High in EPA/DHA omega-3 fatty acids that dampen inflammatory cascades.")
            }
            if (name.contains("berry") || name.contains("blueberr") || name.contains("strawberr") || name.contains("raspberr")) && !positiveHighlights.contains(where: { $0.contains("Antioxidant") }) {
                positiveHighlights.append("Antioxidant anthocyanins protect ovarian cellular health.")
            }
            if (name.contains("cinnamon") || name.contains("turmeric") || name.contains("ginger") || name.contains("garlic")) && !positiveHighlights.contains(where: { $0.contains("Anti-inflammatory herbs") }) {
                positiveHighlights.append("Anti-inflammatory herbs and spices that stimulate healthy metabolic pathways.")
            }
        }

        if positiveHighlights.isEmpty {
            positiveHighlights.append("Nutrient-dense home-cooked recipe supporting whole-body well-being.")
        }

        // 4. Evidence-based Pairing Tips
        var pairingTips: [String] = []
        pairingTips.append("Sequencing: Enjoy any fiber or protein components first to buffer the absorption of starches.")
        if hasRefinedCarbs || hasRefinedSugar {
            pairingTips.append("Digestive Aid: 1 tbsp apple cider vinegar in warm water before the meal can improve insulin sensitivity by up to 34%.")
        }
        pairingTips.append("Gentle Movement: A brief 10-15 minute walk after eating directs glucose into muscle cells without needing extra insulin.")

        // 5. Summary Note
        let focusSummary = settings.focusAreas.isEmpty
            ? "PCOS wellness"
            : settings.focusAreas.map { $0.displayName.lowercased() }.joined(separator: ", ")

        let summaryNote: String
        if glycemicImpactBadge == "Blood Sugar Balanced" {
            summaryNote = "This recipe offers a steady nutritional foundation for \(focusSummary). It naturally combines sustaining macros with minimal glycemic volatility."
        } else {
            summaryNote = "This recipe has wonderful flavor potential! With a few gentle additions or smart pairings, it becomes an empowering meal for \(focusSummary)."
        }

        return PCOSAnalysisResult(
            summaryNote: summaryNote,
            glycemicImpactBadge: glycemicImpactBadge,
            swaps: swaps,
            pairingTips: pairingTips,
            positiveHighlights: positiveHighlights
        )
    }
}
