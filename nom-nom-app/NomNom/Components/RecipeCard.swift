import SwiftUI

/// A recipe tile: cover image with a gradient-backed title and a favorite badge.
/// Ports the card rendering in RN `components/RecipeList.tsx`.
///
/// Layout is driven by a fixed-size rounded rectangle; the image is an `overlay`
/// so a `scaledToFill` image is clipped to the card and can never widen it.
struct RecipeCard: View {
    let recipe: Recipe
    let height: CGFloat

    /// Same fallback image the RN app used when a recipe has no image.
    private static let fallbackImage = URL(
        string: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400"
    )

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                CachedAsyncImage(url: imageURL)
            }
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
            .overlay(alignment: .bottomLeading) {
                Text(recipe.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.nnError)
                        .padding(6)
                        .background(.white.opacity(0.9), in: Circle())
                        .padding(8)
                }
            }
    }

    private var imageURL: URL? {
        if let raw = recipe.imageURL, !raw.isEmpty, let url = URL(string: raw) {
            return url
        }
        return Self.fallbackImage
    }
}
