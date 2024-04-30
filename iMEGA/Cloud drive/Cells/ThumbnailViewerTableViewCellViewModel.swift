import Foundation
import MEGADomain
import MEGAPresentation

@objc final class ThumbnailViewerTableViewCellViewModel: NSObject {
    
    private let thumbnailViewModels: [ItemCollectionViewCellViewModel]
    
    init(nodes: [NodeEntity],
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.thumbnailViewModels = nodes.map {
            ItemCollectionViewCellViewModel(node: $0, nodeUseCase: nodeUseCase, featureFlagProvider: featureFlagProvider)
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
