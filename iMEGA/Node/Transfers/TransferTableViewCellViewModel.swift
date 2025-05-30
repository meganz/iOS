import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import UIKit

@MainActor
@objc public final class TransferTableViewCellViewModel: NSObject, ViewModelType {
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    private var loadDownloadTransferThumbnailTask: Task<Void, any Error>? {
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
    }
    
    init(thumbnailUseCase: some ThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    public func dispatch(_ action: Action) {
        switch action {
        case .configureDownloadTransfer(let transferEntity):
            configureDownloadTransfer(transferEntity: transferEntity)
        }
    }
    
    private func configureDownloadTransfer(transferEntity: TransferEntity) {
        if
            let cachedThumbnailEntity = thumbnailUseCase.cachedThumbnail(for: transferEntity.nodeHandle, type: .thumbnail),
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
            let thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: transferEntity.nodeHandle, type: .preview)
            try Task.checkCancellation()
            guard let thumbnail = try UIImage(data: Data(contentsOf: thumbnailEntity.url)) else { return }
            self?.invokeCommand?(.updateThumbnail(thumbnail))
        }
    }
}
