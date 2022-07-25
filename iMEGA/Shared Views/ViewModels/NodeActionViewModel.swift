import Foundation

struct NodeActionViewModel {
    private var nodeActionUseCase: NodeActionUseCaseProtocol
    
    init(nodeActionUseCase: NodeActionUseCaseProtocol) {
        self.nodeActionUseCase = nodeActionUseCase
    }
    
    func shouldShowSlideShow(with node: NodeEntity, featureFlag enable: Bool = FeatureToggle.slideShow.isEnabled) -> Bool {
        guard enable else { return false }
        guard node.isImage || node.isFolder else { return false }
        
        if node.isImage {
            return true
        }
        
        return nodeActionUseCase.slideShowImages(for: node).isNotEmpty
    }
}
