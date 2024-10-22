import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@objc class NodeCollectionViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?

    var hasThumbnail: Bool { node?.hasThumbnail ?? false }
    
    private let node: NodeEntity?
    private let isFromSharedItem: Bool
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var task: Task<Void, Never>?
    
    init(node: NodeEntity?,
         isFromSharedItem: Bool,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.node = node
        self.isFromSharedItem = isFromSharedItem
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        task?.cancel()
        task = nil
    }
    
    @discardableResult
    func configureCell() -> Task<Void, Never> {
        let task = Task { @MainActor [weak self] in
            guard let self, let node else { return }
            await applySensitiveConfiguration(for: node)
            await loadThumbnail(for: node)
        }
        self.task = task
        return task
    }
    
    @objc func isNodeVideo() -> Bool {
        node?.name.fileExtensionGroup.isVideo ?? false
    }
    
    @objc func isNodeVideo(name: String) -> Bool {
        name.fileExtensionGroup.isVideo
    }
    
    @objc func isNodeVideoWithValidDuration() -> Bool {
        guard let node else { return false }
        return isNodeVideo(name: node.name) && node.duration >= 0
    }
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
                
        guard hasThumbnail else {
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
            
            let imagePath = if #available(iOS 16.0, *) {
                thumbnailEntity.url.path()
            } else {
                thumbnailEntity.url.path
            }
            
            thumbnail = UIImage(contentsOfFile: imagePath)
        } catch {
            MEGALogError("[\(type(of: self))] Error loading thumbnail: \(error)")
        }
    }
    
    @MainActor
    private func applySensitiveConfiguration(for node: NodeEntity) async {
        guard !isFromSharedItem,
              featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
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
}
