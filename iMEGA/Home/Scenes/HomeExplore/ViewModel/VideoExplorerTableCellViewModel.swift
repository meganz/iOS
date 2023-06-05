import Foundation
import MEGADomain

final class VideoExplorerTableCellViewModel {
    private let node: MEGANode
    typealias MoreButtonTapHandler = (MEGANode, UIView) -> Void
    private let moreButtonTapHandler: MoreButtonTapHandler
    private lazy var nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol = {
        return NodeThumbnailHomeUseCase(sdkNodeClient: .live,
                                        fileSystemClient: .live,
                                        thumbnailRepo: ThumbnailRepository.newRepo)
    }()
    
    var title: String {
        return node.name ?? ""
    }
    
    var duration: String? {
        return node.duration >= 0 ? TimeInterval(node.duration).timeString : nil
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
    
    func createAttributedTitle() -> NSAttributedString? {
        let attributedTitle = NSMutableAttributedString(string: title)
        
        if node.isFavourite {
            let space = createSpace()
            let favouriteIcon = createFavouriteIcon()
            attributedTitle.append(space)
            attributedTitle.append(favouriteIcon)
        }
        
        return attributedTitle.copy() as? NSAttributedString
    }
    
    // MARK: - Private
    
    private func createSpace(_ width: Double = 4) -> NSAttributedString {
        let spaceAttachment = NSTextAttachment()
        spaceAttachment.bounds = CGRect(x:0, y: 0, width: width, height: 0)
        let space = NSAttributedString(attachment: spaceAttachment)
        return space
    }
    
    private func createFavouriteIcon() -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = Asset.Images.Labels.favouriteSmall.image
        imageAttachment.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        let favouriteIcon = NSAttributedString(attachment: imageAttachment)
        return favouriteIcon
    }
}
