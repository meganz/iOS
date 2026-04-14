import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import UIKit

@MainActor
@objc public final class TransferTableViewCellViewModel: NSObject, ViewModelType {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    /// Caches cell-sized thumbnails for upload transfers. 100 covers visible
    /// cells (~15-20) plus a generous scroll-back buffer. NSCache auto-evicts
    /// under memory pressure, so this limit is a secondary safeguard.
    private static let uploadThumbnailCache: NSCache<NSString, UIImage> = {
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
    @objc static func evictUploadThumbnail(forPath path: String) {
        uploadThumbnailCache.removeObject(forKey: path as NSString)
    }

    func cancelThumbnailLoading() {
        loadDownloadTransferThumbnailTask = nil
        loadUploadTransferThumbnailTask = nil
    }

    // MARK: - Private

    private func configureDownloadTransfer(transferEntity: TransferEntity) {
        if let cachedThumbnailEntity = thumbnailUseCase.cachedThumbnail(for: transferEntity.nodeHandle, type: .thumbnail),
           let cachedThumbnail = try? UIImage(data: Data(contentsOf: cachedThumbnailEntity.url)) {
            invokeCommand?(.updateThumbnail(cachedThumbnail))
            return
        }
        
        let defaultThumbnail = if let fileName = transferEntity.fileName {
            MEGAAssets.UIImage.image(forFileName: fileName)
        } else {
            MEGAAssets.UIImage.filetypeGeneric
        }
        invokeCommand?(.updateThumbnail(defaultThumbnail))
        loadDownloadTransferThumbnailTask = Task { [weak self, thumbnailUseCase] in
            let thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: transferEntity.nodeHandle, type: .thumbnail)
            try Task.checkCancellation()
            guard let thumbnail = try UIImage(data: Data(contentsOf: thumbnailEntity.url)) else { return }
            self?.invokeCommand?(.updateThumbnail(thumbnail))
        }
    }
    
    private func configureUploadTransfer(transferEntity: TransferEntity) {
        guard let path = transferEntity.path else {
            return
        }

        let cacheKey = path as NSString
        if let cachedImage = Self.uploadThumbnailCache.object(forKey: cacheKey) {
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
            Self.uploadThumbnailCache.setObject(image, forKey: cacheKey)
            self?.invokeCommand?(.updateThumbnail(image))
        }
    }
}
