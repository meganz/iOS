
protocol FileExplorerGridCellViewModelDelegate: AnyObject {
    func onUpdateAllowsSelection()
    func onUpdateMarkSelection()
    func updateSelection()
}

final class FileExplorerGridCellViewModel {
    private let node: MEGANode
    typealias MoreInfoActionBlock = (MEGANode, UIButton) -> Void
    private let moreInfoAction: MoreInfoActionBlock?
    
    private lazy var nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol = {
        return NodeThumbnailHomeUseCase(sdkNodeClient: .live,
                                        fileSystemClient: .live,
                                        thumbnailRepo: ThumbnailRepository.newRepo)
    }()
    
    private weak var delegate: FileExplorerGridCellViewModelDelegate?
    
    var allowsSelection: Bool {
        didSet {
            delegate?.onUpdateAllowsSelection()
        }
    }
    
    var markSelection: Bool {
        didSet {
            delegate?.onUpdateMarkSelection()
        }
    }
    
    var name: String {
        return node.name ?? ""
    }
    
    var nodeHandle: UInt64 {
        return node.handle
    }
    
    var hasThumbnail: Bool {
        return node.hasThumbnail()
    }
    
    var isTakenDown: Bool {
        return node.isTakenDown()
    }
    
    var isVideo: Bool {
        return (name as NSString).mnz_isVideoPathExtension
    }
    
    var sizeDescription: String {
        return Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
    }
    
    init(node: MEGANode,
         allowsSelection: Bool = false,
         markSelection: Bool = false,
         delegate: FileExplorerGridCellViewModelDelegate? = nil,
         moreInfoAction: MoreInfoActionBlock? = nil) {
        self.node = node
        self.allowsSelection = allowsSelection
        self.markSelection = markSelection
        self.delegate = delegate
        self.moreInfoAction = moreInfoAction
    }
    
    func loadThumbnail(completionBlock: @escaping (UIImage?, UInt64) -> Void) {
        nodeThumbnailHomeUseCase.loadThumbnail(of: node.handle) { [weak self] image in
            guard let self = self else { return }
            completionBlock(image, self.node.handle)
        }
    }
    
    func moreButtonTapped(_ button: UIButton) {
        moreInfoAction?(node, button)
    }
    
    func updateSelection() {
        delegate?.updateSelection()
    }
}
