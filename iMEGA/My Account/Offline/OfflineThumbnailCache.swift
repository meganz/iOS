import MEGADomain
import MEGARepo
import UIKit

/// In-memory cache for thumbnails generated on the fly for Offline items.
///
/// An Offline item only gets a `thumbnailsV3` entry on disk when it has a `MOOfflineNode` record.
/// Files downloaded as part of a folder never get one, so their thumbnail is produced through
/// `FileAttributeGenerator` on every cell configuration and is never persisted. Because the Offline
/// list does a full `reloadData` on each download completion, that meant regenerating the thumbnail
/// asynchronously roughly once per second while showing the file type placeholder in between, which
/// is the flashing reported in IOS-10912.
@MainActor
final class OfflineThumbnailCache {
    static let shared = OfflineThumbnailCache()

    private enum Constants {
        static let countLimit = 500
        static let totalCostLimit = 32 * 1024 * 1024
    }

    /// `NSCache` constrains its key to `AnyObject`, so `NSString` is confined to the calls below.
    private let cache = NSCache<NSString, UIImage>()
    private var pendingGenerations = [String: Task<UIImage?, Never>]()
    private let makeThumbnailGenerator: (URL) -> any FileAttributeGeneratorProtocol
    private var invalidationTasks: [Task<Void, Never>] = []

    init(
        notificationCenter: NotificationCenter = .default,
        makeThumbnailGenerator: @escaping (URL) -> any FileAttributeGeneratorProtocol = {
            FileAttributeGenerator(sourceURL: $0)
        }
    ) {
        self.makeThumbnailGenerator = makeThumbnailGenerator
        cache.countLimit = Constants.countLimit
        cache.totalCostLimit = Constants.totalCostLimit

        invalidationTasks = [UIApplication.didReceiveMemoryWarningNotification, .accountDidLogout]
            .map { name in
                Task.detached { [weak self] in
                    for await _ in notificationCenter.notifications(named: name) {
                        await self?.removeAll()
                    }
                }
            }
    }

    deinit {
        invalidationTasks.forEach { $0.cancel() }
    }

    /// Already generated thumbnail for `url`, if any. Synchronous so a cell being re-configured can
    /// apply it in the same layout pass and never show the placeholder.
    func image(for url: URL) -> UIImage? {
        guard let key = key(for: url) else { return nil }
        return cache.object(forKey: key as NSString)
    }

    /// Thumbnail for `url`, generating and caching it if needed
    func thumbnail(for url: URL) async -> UIImage? {
        guard let key = key(for: url) else { return nil }

        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        if let pending = pendingGenerations[key] {
            return await pending.value
        }

        let generator = makeThumbnailGenerator(url)
        let generation = Task { @MainActor [weak self] in
            // A generation is the only owner of its entry, so it retires it on every exit. Leaving
            // one behind would make every later request for the file replay its result instead of
            // generating again.
            defer { self?.pendingGenerations[key] = nil }

            let image = await Task.detached(priority: .userInitiated) {
                await generator.requestThumbnail()
            }.value

            guard let self, !Task.isCancelled else { return image }

            if let image {
                cache.setObject(image, forKey: key as NSString, cost: image.estimatedByteCount)
            }
            return image
        }

        pendingGenerations[key] = generation
        return await generation.value
    }

    func removeAll() {
        pendingGenerations.values.forEach { $0.cancel() }
        pendingGenerations.removeAll()
        cache.removeAllObjects()
    }

    /// Keyed on path plus modification date so a file replaced by a new download never serves a
    /// stale thumbnail. Both callers only ever pass a file that exists under `Helper.pathForOffline`,
    /// and returning `nil` here — which makes the cache a no-op — is the intended behaviour for
    /// anything else, since `requestThumbnail()` could not produce an image for it either.
    private func key(for url: URL) -> String? {
        guard url.isFileURL,
              let modificationDate = try? url
            .resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate else {
            return nil
        }
        return "\(url.path)|\(modificationDate.timeIntervalSince1970)"
    }
}

private extension UIImage {
    var estimatedByteCount: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
