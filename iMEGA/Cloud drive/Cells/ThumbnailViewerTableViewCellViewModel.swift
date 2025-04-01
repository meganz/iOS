import Foundation
import MEGAAppPresentation
import MEGADomain

@MainActor
@objc final class ThumbnailViewerTableViewCellViewModel: NSObject {
    
    private let thumbnailViewModels: [ItemCollectionViewCellViewModel]
    
    init(nodes: [NodeEntity],
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        
        self.thumbnailViewModels = nodes.map {
            ItemCollectionViewCellViewModel(
                node: $0,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                thumbnailUseCase: thumbnailUseCase,
                nodeIconUseCase: nodeIconUseCase,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        }
    }
    
    @objc func item(for index: Int) -> ItemCollectionViewCellViewModel? {
        
        guard let itemViewModel = thumbnailViewModels[safe: index] else {
            MEGALogError("Error fetching item at index (\(index)) for ThumbnailViewerTableViewCellViewModel")
            return nil
        }
        return itemViewModel
    }
}
