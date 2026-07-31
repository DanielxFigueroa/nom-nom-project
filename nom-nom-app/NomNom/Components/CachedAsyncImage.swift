import SwiftUI
import UIKit

/// Simple in-memory image cache shared across the app.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

/// A drop-in replacement for `AsyncImage` that caches downloaded images in memory
/// and renders them `scaledToFill`. Unlike `AsyncImage`, a cached image shows
/// instantly on re-render/reload, so list refreshes don't blank out the tiles.
struct CachedAsyncImage: View {
    let url: URL?

    private enum Phase {
        case loading
        case success(UIImage)
        case failure
    }

    @State private var phase: Phase = .loading

    var body: some View {
        content
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .success(let image):
            Image(uiImage: image).resizable().scaledToFill()
        case .failure:
            Color(.systemGray4)
        case .loading:
            Color(.systemGray5)
        }
    }

    private func load() async {
        guard let url else {
            phase = .failure
            return
        }
        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(cached)
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }
            if let image = UIImage(data: data) {
                ImageCache.shared.insert(image, for: url)
                phase = .success(image)
            } else {
                phase = .failure
            }
        } catch {
            if !Task.isCancelled { phase = .failure }
        }
    }
}
