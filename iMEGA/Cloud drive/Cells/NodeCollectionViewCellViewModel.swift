import MEGADomain

@objc class NodeCollectionViewCellViewModel: NSObject {
    private let mediaUseCase: MediaUseCaseProtocol
    
    init(mediaUseCase: MediaUseCaseProtocol) {
        self.mediaUseCase = mediaUseCase
    }
    
    @objc func isNodeVideo(name: String) -> Bool {
        mediaUseCase.isVideo(name)
    }
    
    @objc func isNodeVideoWithValidDuration(node: MEGANode) -> Bool {
        guard let nodeName = node.name else { return false }
        return isNodeVideo(name: nodeName) && node.duration >= 0
    }
    
}
