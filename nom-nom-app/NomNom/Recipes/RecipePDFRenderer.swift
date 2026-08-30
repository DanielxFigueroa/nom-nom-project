import SwiftUI
import UIKit

enum PDFRenderError: LocalizedError {
    case contextCreationFailed
    case renderingFailed(String)

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed:
            return "Unable to create PDF graphics context."
        case .renderingFailed(let msg):
            return "Failed to render PDF: \(msg)"
        }
    }
}

/// Utility for rendering structured recipe documents into printable PDF files.
@MainActor
final class RecipePDFRenderer {

    /// Generates a PDF file in the temporary directory for the specified recipe.
    static func generatePDF(
        recipe: Recipe,
        ingredients: [Ingredient],
        tags: [Tag],
        desiredServings: Int,
        scaleFactor: Double
    ) async throws -> URL {
        // Pre-fetch header image so it is synchronously available during ImageRenderer execution
        var headerImage: UIImage? = nil
        if let raw = recipe.imageURL, !raw.isEmpty, let url = URL(string: raw) {
            if let cached = ImageCache.shared.image(for: url) {
                headerImage = cached
            } else if let (data, _) = try? await URLSession.shared.data(from: url), let img = UIImage(data: data) {
                ImageCache.shared.insert(img, for: url)
                headerImage = img
            }
        }

        let printWidth: CGFloat = 612 // Standard US Letter width in points

        let documentView = RecipePDFDocumentView(
            recipe: recipe,
            ingredients: ingredients,
            tags: tags,
            desiredServings: desiredServings,
            scaleFactor: scaleFactor,
            headerImage: headerImage,
            pageWidth: printWidth,
            exportDate: Date()
        )

        let renderer = ImageRenderer(content: documentView)
        renderer.proposedSize = ProposedViewSize(width: printWidth, height: nil)
        renderer.scale = 2.0

        let safeTitle = sanitizeFileName(recipe.title)
        let uniqueSuffix = String(UUID().uuidString.prefix(6))
        let fileName = "NomNom_\(safeTitle)_\(uniqueSuffix).pdf"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Remove any pre-existing file at the target path
        try? FileManager.default.removeItem(at: outputURL)

        var renderError: Error?
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdfContext = CGContext(outputURL as CFURL, mediaBox: &box, nil) else {
                renderError = PDFRenderError.contextCreationFailed
                return
            }

            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }

        if let renderError {
            throw renderError
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw PDFRenderError.renderingFailed("Output file could not be verified.")
        }

        return outputURL
    }

    private static func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|").union(.newlines).union(.controlCharacters)
        let safe = name.components(separatedBy: invalidCharacters).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        return safe.isEmpty ? "Recipe" : safe
    }
}
