import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@objc final class ItemCollectionViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?
    
    let node: NodeEntity
    let isVideo: Bool
    let hasThumbnail: Bool
    
    private let nodeUseCase: any NodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var task: Task<Void, Never>?
    
    init(node: NodeEntity,
         nodeUseCase: some NodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.node = node
        self.hasThumbnail = node.hasThumbnail
        self.isVideo = node.name.fileExtensionGroup.isVideo
        self.nodeUseCase = nodeUseCase
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
        if let task {
            return task
        } else {
            let task = Task { [weak self] in
                guard let self else { return }
                await applySensitiveConfiguration()
                await loadThumbnail()
            }
            self.task = task
            return task
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
        
        self.thumbnail = UIImage(data: nodeIconUseCase.iconData(for: node))
        
        guard hasThumbnail else {
            return
        }
        
        do {
            let thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            let imagePath = if #available(iOS 16.0, *) {
                thumbnailEntity.url.path()
            } else {
                thumbnailEntity.url.path
            }
            
            guard let image = UIImage(contentsOfFile: imagePath) else {
                return
            }
            
            self.thumbnail = image
        } catch {
            print("[ItemCollectionViewCellViewModel] Error loading thumbnail: \(error)")
        }
    }
    
    @MainActor
    private func applySensitiveConfiguration() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            isSensitive = false
            return
        }
        
        guard !node.isMarkedSensitive else {
            isSensitive = true
            return
        }
        
        do {
            isSensitive = try await nodeUseCase.isInheritingSensitivity(node: node)
        } catch {
            MEGALogError("Error checking if node is inheriting sensitivity: \(error)")
        }
    }
}
