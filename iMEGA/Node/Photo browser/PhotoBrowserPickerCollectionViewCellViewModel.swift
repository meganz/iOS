import Combine
import MEGAAppPresentation
import MEGADomain

@MainActor
@objc class PhotoBrowserPickerCollectionViewCellViewModel: NSObject {
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?
    let hasThumbnail: Bool
    @objc let isVideo: Bool
    
    var videoDuration: String {
        if let node, isVideo, node.duration > -1 {
            TimeInterval(node.duration).timeString
        } else {
            ""
        }
    }
    
    private let node: NodeEntity?
    private let isFromSharedItem: Bool
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private var task: Task<Void, Never>?
    
    init(node: NodeEntity?,
         isFromSharedItem: Bool,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.node = node
        self.isFromSharedItem = isFromSharedItem
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        hasThumbnail = node?.hasThumbnail ?? false
        isVideo = node?.name.fileExtensionGroup.isVideo ?? false
    }

    deinit {
        task?.cancel()
        task = nil
    }
    
    @discardableResult
    func configureCell() -> Task<Void, Never> {
        let task = Task { [weak self] in
            guard let self, let node else { return }
            await applySensitiveConfiguration(for: node)
            await loadThumbnail(for: node)
        }
        self.task = task
        return task
    }
    
    private func applySensitiveConfiguration(for node: NodeEntity) async {
        guard !isFromSharedItem,
              remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              sensitiveNodeUseCase.isAccessible() else {
            isSensitive = false
            return
        }
                
        guard !node.isMarkedSensitive else {
            isSensitive = true
            return
        }
        
        do {
            isSensitive = try await sensitiveNodeUseCase.isInheritingSensitivity(node: node)
        } catch {
            MEGALogError("[\(type(of: self))] Error checking if node is inheriting sensitivity: \(error)")
        }
    }
    
    private func loadThumbnail(for node: NodeEntity) async {
        guard node.hasThumbnail else {
            thumbnail = UIImage(data: nodeIconUseCase.iconData(for: node))
            return
        }
        
        do {
            let thumbnailEntity: ThumbnailEntity
            if let cached = thumbnailUseCase.cachedThumbnail(for: node, type: .thumbnail) {
                thumbnailEntity = cached
            } else {
                thumbnail = UIImage(data: nodeIconUseCase.iconData(for: node))
                thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            }
            
            let imagePath = thumbnailEntity.url.path()
            thumbnail = UIImage(contentsOfFile: imagePath)
        } catch {
            MEGALogError("[\(type(of: self))] Error loading thumbnail: \(error)")
        }
    }
}
