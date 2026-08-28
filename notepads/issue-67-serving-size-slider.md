# Issue #67: iOS — Serving size slider with dynamic ingredient scaling

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/67

## Summary
Replace the serving size stepper in `RecipeDetailView` with an interactive, fluid slider that allows users to quickly scale recipe serving sizes up and down, dynamically updating ingredient quantities in real time with haptic sensory feedback.

## Implementation Plan

### Task 1: Update `RecipeDetailModel.swift`
- Add `maxServings` computed property (`max(24, recipe.servings)`).
- Add `desiredServingsDouble` computed property (getter and setter with rounding/clamping) for clean SwiftUI `Slider` two-way binding.
- Add helper methods `incrementServings()` and `decrementServings()` bounded by `1...maxServings`.
- Ensure `scaleFactor`, `formattedLabel(for:)`, and `resetServings()` handle dynamic scale changes gracefully.

### Task 2: Update `RecipeDetailView.swift`
- Replace `servingsStepperHeader` with `servingsSliderHeader`.
- Header UX layout:
  - Top row: "Servings" title and "Serves X · base Y" subtitle on the left; "Reset" button (when `model.isServingScaled`) on the right.
  - Controls row: Flanking decrement (`-`) and increment (`+`) buttons, custom slider (`1...maxServings`, step: 1) styled with `Color.nnTint`, and min/max serving labels (`1` and `24`).
- Add iOS 17 `.sensoryFeedback(.selection, trigger: model.desiredServings)` for light haptic feedback on each serving value snap.
- Wrap serving adjustments in smooth animations (`withAnimation`) so ingredient quantities update dynamically and smoothly.

### Task 3: Review `FractionFormatter.swift` & `MeasurementUnits.swift`
- Verify scaling across fractional and whole values, metric and imperial systems.

### Task 4: Test & Build Gate
- Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
- Verify `** BUILD SUCCEEDED **`.
