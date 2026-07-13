import MEGADomain
import MEGARepo
import UIKit

/// Cell-sized thumbnail loading for transfer rows, backed by an in-memory `NSCache`.
///
/// - Downloads (and completed uploads, via the created node's handle) read the
///   SDK's locally-cached thumbnail first and fall back to fetching the node
///   thumbnail from the server — same strategy as the legacy widget cell.
/// - In-flight uploads generate a thumbnail from the staged local file via
///   QuickLook (`FileAttributeGenerator`).
/// - Returns `nil` when no source produces an image; the row then keeps its
///   file-type icon.
@MainActor
final class TransferThumbnailLoader {
    /// Keys are `dl_<nodeHandle>` for downloads and `ul_<localPath>` for uploads —
    /// they never collide. 100 covers visible rows plus a generous scroll-back
    /// buffer; NSCache additionally auto-evicts under memory pressure.
    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        return cache
    }()

    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let makeUploadThumbnailGenerator: (URL) -> any FileAttributeGeneratorProtocol

    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        makeUploadThumbnailGenerator: @escaping (URL) -> any FileAttributeGeneratorProtocol = {
            FileAttributeGenerator(sourceURL: $0)
        }
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.makeUploadThumbnailGenerator = makeUploadThumbnailGenerator
    }

    func image(for transfer: TransferEntity) async throws -> UIImage? {
        switch transfer.type {
        case .download: try await downloadImage(for: transfer)
        case .upload: try await uploadImage(for: transfer)
        case .localHTTPDownload: nil
        }
    }

    /// Re-keys a staged-upload cache entry to the created node's handle once the
    /// upload completes. The staged file is deleted on success, so the `ul_` entry
    /// can never hit again — but the same image remains valid for the node, so
    /// re-displays (and the Completed tab) keep hitting the cache under `dl_`.
    /// With an invalid handle this degrades to plain eviction.
    func migrateUploadThumbnail(fromPath path: String, toNodeHandle nodeHandle: HandleEntity) {
        let uploadKey = "ul_\(path)" as NSString
        defer { cache.removeObject(forKey: uploadKey) }
        guard nodeHandle != .invalid, let image = cache.object(forKey: uploadKey) else { return }
        cache.setObject(image, forKey: "dl_\(nodeHandle)" as NSString)
    }

    // MARK: - Private

    private func downloadImage(for transfer: TransferEntity) async throws -> UIImage? {
        let key = "dl_\(transfer.nodeHandle)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let thumbnailURL: URL
        if let cachedThumbnail = thumbnailUseCase.cachedThumbnail(for: transfer.nodeHandle, type: .thumbnail) {
            thumbnailURL = cachedThumbnail.url
        } else {
            do {
                thumbnailURL = try await thumbnailUseCase.loadThumbnail(for: transfer.nodeHandle, type: .thumbnail).url
            } catch is ThumbnailErrorEntity {
                // Definitive: the node has no thumbnail attribute (apiENoent), the row keeps its file-type icon.
                return nil
            }
            // Any other error propagates as transient.
        }

        guard !Task.isCancelled, let image = await Self.decodeImage(at: thumbnailURL) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private func uploadImage(for transfer: TransferEntity) async throws -> UIImage? {
        if transfer.nodeHandle != .invalid, let image = try await downloadImage(for: transfer) {
            return image
        }
        guard let path = transfer.path else { return nil }
        let key = "ul_\(path)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = await makeUploadThumbnailGenerator(URL(fileURLWithPath: path)).requestThumbnail() else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    @concurrent
    private static func decodeImage(at url: URL) async -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        return await image.byPreparingForDisplay()
    }
}
