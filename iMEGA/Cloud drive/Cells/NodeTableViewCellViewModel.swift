import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@objc final class NodeTableViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?
    let hasThumbnail: Bool
    
    private let nodes: [NodeEntity]
    private let shouldApplySensitiveBehaviour: Bool
    private let nodeUseCase: any NodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var task: Task<Void, Never>?
    
    init(nodes: [NodeEntity],
         shouldApplySensitiveBehaviour: Bool,
         nodeUseCase: some NodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.nodes = nodes
        self.hasThumbnail = [
            nodes.count == 1,
            nodes.first?.hasThumbnail ?? false
        ].allSatisfy { $0 }
        self.shouldApplySensitiveBehaviour = shouldApplySensitiveBehaviour
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
        let task = Task { [weak self] in
            guard let self else { return }
            await applySensitiveConfiguration(for: nodes)
            await loadThumbnail()
        }
        self.task = task
        return task
    }
    
    @MainActor
    private func loadThumbnail() async {
        
        guard let node = nodes.first else {
            return
        }
        
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
            MEGALogError("[ItemCollectionViewCellViewModel] Error loading thumbnail: \(error)")
        }
    }
    
    @MainActor
    private func applySensitiveConfiguration(for nodes: [NodeEntity]) async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              shouldApplySensitiveBehaviour else {
            isSensitive = false
            return
        }
        
        guard nodes.count == 1,
              let node = nodes.first else {
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
            MEGALogError("[\(type(of: self))] Error checking if node is inheriting sensitivity: \(error)")
        }
    }
}
