import Foundation

final class VideoExplorerTableCellViewModel {
    private let node: MEGANode
    typealias MoreButtonTapHandler = (MEGANode, UIView) -> Void
    private let moreButtonTapHandler: MoreButtonTapHandler
    private lazy var nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol = {
        return NodeThumbnailHomeUseCase(sdkNodeClient: .live,
                                        fileSystemClient: .live,
                                        thumbnailRepo: ThumbnailRepository.default)
    }()
    
    var title: String {
        return node.name ?? ""
    }
    
    var duration: String? {
        return TimeInterval(node.duration).timeDisplayString()
    }
    
    var parentFolderName: String {
        return node.parent.name ?? ""
    }
    
    var hasThumbnail: Bool {
        return node.hasThumbnail()
    }
    
    var nodeHandle: UInt64 {
        return node.handle
    }
    
    init(node: MEGANode, moreButtonTapHandler: @escaping MoreButtonTapHandler) {
        self.node = node
        self.moreButtonTapHandler = moreButtonTapHandler
    }
    
    func loadThumbnail(completionBlock: @escaping (UIImage?, UInt64) -> Void) {
        nodeThumbnailHomeUseCase.loadThumbnail(of: node.handle) { [weak self] image in
            guard let self = self else { return }
            completionBlock(image, self.node.handle)
        }
    }
    
    func moreButtonTapped(cell: UIView) {
        moreButtonTapHandler(node, cell)
    }
}
