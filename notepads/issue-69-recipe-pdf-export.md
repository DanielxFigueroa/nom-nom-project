# Issue #69: iOS — Export recipes to organized PDF format

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/69

## Summary
Allow users to export and share complete recipes as beautifully formatted, printable PDF documents directly from the iOS application via the native iOS share sheet.

## Implementation Plan

### Task 1: Create ActivityView UIViewControllerRepresentable
- Create `nom-nom-app/NomNom/Components/ActivityView.swift`.
- Wrap `UIActivityViewController` in SwiftUI `UIViewControllerRepresentable`.
- Ensure proper configuration for iPad popovers (`popoverPresentationController`) to prevent crashes on iPad.
- Support completion callbacks for cleaning up temporary files after sharing.

### Task 2: Create RecipePDFDocumentView and RecipePDFRenderer
- Create `nom-nom-app/NomNom/Recipes/RecipePDFDocumentView.swift`:
  - Design a clean, high-contrast, print-friendly layout formatted for standard letter width (white background, dark typography).
  - Include:
    - Subtle NomNom header and generation timestamp.
    - Recipe title, description, and tags (with special styling for PCOS tag).
    - Metadata pills: Servings (scaled vs base), Measurement System (Imperial/Metric), Ingredients count.
    - Preloaded header image / recipe photo (if available).
    - Ingredients section with scaled quantities and formatted units.
    - Step-by-step instructions rendered cleanly.
    - Footer with branding and generation date.
- Create `nom-nom-app/NomNom/Recipes/RecipePDFRenderer.swift`:
  - Asynchronously fetch/cache recipe hero image to ensure image renders into PDF.
  - Utilize SwiftUI `ImageRenderer` with `ProposedViewSize` and 2x scale for crisp vector/raster PDF output.
  - Write PDF data to a sanitized unique temporary file in `FileManager.default.temporaryDirectory`.
  - Return temporary file URL.

### Task 3: Update RecipeDetailModel
- Add `isExportingPDF: Bool`.
- Add `exportedPDF: ExportedPDF?` struct with `Identifiable` for `.sheet(item:)`.
- Add `pdfErrorMessage: String?`.
- Add `exportPDF()` async method coordinating image loading, PDF generation, error handling, and state updates.
- Add `cleanupExportedPDF()` to delete temporary `.pdf` files when share sheet is dismissed.

### Task 4: Update RecipeDetailView UI
- Add `square.and.arrow.up` button to the `RecipeDetailView` navigation toolbar with loading indicator state.
- Wire `.sheet(item: $model.exportedPDF)` to present `ActivityView`.
- Show user-friendly error banners if PDF generation fails.

### Task 5: Build Gate & Testing
- Run `xcodegen generate`.
- Run `xcodebuild` targeting iOS Simulator.
- Verify `** BUILD SUCCEEDED **`.
