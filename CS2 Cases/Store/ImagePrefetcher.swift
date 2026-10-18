//
//  ImagePrefetcher.swift
//  CS2 Cases
//
//  Downloads and fully decodes a case's skin images up front and keeps them
//  in memory. AsyncImage only starts a request once a card is on screen and
//  decodes asynchronously, so at reel speed cards fly past as spinners and
//  the art only shows up once the reel has slowed down. Drawing reel cards
//  from already-decoded images means every skin is visible for the whole
//  spin.
//

import Observation
import UIKit

@MainActor
@Observable
final class SkinImageStore {
    static let shared = SkinImageStore()

    private(set) var images: [URL: UIImage] = [:]

    func image(for url: URL?) -> UIImage? {
        guard let url else { return nil }
        return images[url]
    }

    /// Loads every missing image concurrently; returns once all have either
    /// arrived or failed.
    func preload(_ urls: [URL]) async {
        let missing = Set(urls).filter { images[$0] == nil }
        guard !missing.isEmpty else { return }

        await withTaskGroup(of: (URL, UIImage?).self) { group in
            for url in missing {
                group.addTask { (url, await Self.fetch(url)) }
            }
            for await (url, image) in group {
                if let image { images[url] = image }
            }
        }
    }

    private nonisolated static func fetch(_ url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        // Decode now, off the main thread, so the first frame a card is
        // drawn doesn't stall the reel animation.
        return await image.byPreparingForDisplay() ?? image
    }
}
