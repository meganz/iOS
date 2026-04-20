import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import UIKit

@MainActor
@objc public final class TransferTableViewCellViewModel: NSObject, ViewModelType {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    /// Caches decoded cell-sized thumbnails for transfers. Keys are file paths
    /// for uploads and node handles for downloads — they never collide. 100
    /// covers visible cells (~15-20) plus a generous scroll-back buffer.
    /// NSCache auto-evicts under memory pressure, so this limit is a secondary
    /// safeguard.
    private static let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        return cache
    }()

    private var loadDownloadTransferThumbnailTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private var loadUploadTransferThumbnailTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public enum Command: CommandType {
        case updateThumbnail(UIImage)
    }
    
    public enum Action: ActionType {
        case configureDownloadTransfer(TransferEntity)
        case configureUploadTransfer(TransferEntity)
    }
    
    init(thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    public func dispatch(_ action: Action) {
        switch action {
        case .configureDownloadTransfer(let transferEntity):
            configureDownloadTransfer(transferEntity: transferEntity)
        case .configureUploadTransfer(let transferEntity):
            configureUploadTransfer(transferEntity: transferEntity)
        }
    }

    /// Evicts the cached upload thumbnail for the given file path.
    /// Call when an upload transfer finishes and the staged file is no longer needed.
    ///
    /// Uploads key the cache by the source file path on disk. When the upload
    /// completes the staged file is deleted, so the entry can never hit again
    /// and becomes dead weight — hence the explicit eviction.
    ///
    /// Downloads have no equivalent method on purpose: they key by node handle,
    /// which stays valid after the transfer finishes (the node still exists in
    /// the cloud and the on-disk thumbnail persists). The cached `UIImage` can
    /// still hit on retry or re-display; `NSCache`'s memory-pressure eviction
    /// and `countLimit` handle cleanup.
    @objc static func evictUploadThumbnail(forPath path: String) {
        thumbnailCache.removeObject(forKey: "ul_\(path)" as NSString)
    }

    func cancelThumbnailLoading() {
        loadDownloadTransferThumbnailTask = nil
        loadUploadTransferThumbnailTask = nil
    }

    // MARK: - Private

    private func configureDownloadTransfer(transferEntity: TransferEntity) {
        let cacheKey = "dl_\(transferEntity.nodeHandle)" as NSString
        if let cachedImage = Self.thumbnailCache.object(forKey: cacheKey) {
            invokeCommand?(.updateThumbnail(cachedImage))
            return
        }
        
        let defaultThumbnail = if let fileName = transferEntity.fileName {
            MEGAAssets.UIImage.image(forFileName: fileName)
        } else {
            MEGAAssets.UIImage.filetypeGeneric
        }
        invokeCommand?(.updateThumbnail(defaultThumbnail))

        loadDownloadTransferThumbnailTask = Task { [weak self, thumbnailUseCase] in
            let thumbnailURL: URL
            if let cachedThumbnailEntity = thumbnailUseCase.cachedThumbnail(for: transferEntity.nodeHandle, type: .thumbnail) {
                thumbnailURL = cachedThumbnailEntity.url
            } else {
                let thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: transferEntity.nodeHandle, type: .thumbnail)
                thumbnailURL = thumbnailEntity.url
            }
            try Task.checkCancellation()
            guard let thumbnail = await Self.loadImage(from: thumbnailURL) else { return }
            try Task.checkCancellation()
            Self.thumbnailCache.setObject(thumbnail, forKey: cacheKey)
            self?.invokeCommand?(.updateThumbnail(thumbnail))
        }
    }

    @concurrent
    private static func loadImage(from url: URL) async -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        return await image.byPreparingForDisplay()
    }
    
    private func configureUploadTransfer(transferEntity: TransferEntity) {
        guard let path = transferEntity.path else {
            return
        }

        let cacheKey = "ul_\(path)" as NSString
        if let cachedImage = Self.thumbnailCache.object(forKey: cacheKey) {
            invokeCommand?(.updateThumbnail(cachedImage))
            return
        }

        let url = URL(fileURLWithPath: path)
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        loadUploadTransferThumbnailTask = Task { [weak self] in
            guard let image = await fileAttributeGenerator.requestThumbnail() else {
                let fallback = NodeAssetsManager.shared.image(for: path.pathExtension) ?? MEGAAssets.UIImage.filetypeGeneric
                self?.invokeCommand?(.updateThumbnail(fallback))
                return
            }
            try Task.checkCancellation()
            Self.thumbnailCache.setObject(image, forKey: cacheKey)
            self?.invokeCommand?(.updateThumbnail(image))
        }
    }
}
