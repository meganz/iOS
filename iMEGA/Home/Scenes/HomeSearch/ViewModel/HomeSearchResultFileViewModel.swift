import Combine
import Foundation
import MEGADomain
import MEGAPresentation

final class HomeSearchResultFileViewModel {
    @Published private(set) var isSensitive: Bool
    @Published private(set) var thumbnail: UIImage?
    
    let handle: HandleEntity
    let name: String
    let ownerFolder: String
    let hasThumbnail: Bool
    let moreAction: (HandleEntity, UIButton) -> Void
    
    private let node: NodeEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(node: NodeEntity,
         ownerFolder: String,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol,
         moreAction: @escaping (HandleEntity, UIButton) -> Void) {
        self.node = node
        self.ownerFolder = ownerFolder
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        self.moreAction = moreAction
        handle = node.handle
        name = node.name
        hasThumbnail = node.hasThumbnail
        isSensitive = featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) ? node.isMarkedSensitive : false
    }
    
    @MainActor
    func configureCell() async {
        await applySensitiveConfiguration()
        await loadThumbnail()
    }
    
    @MainActor
    private func applySensitiveConfiguration() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              !node.isMarkedSensitive else {
            return
        }
        
        do {
            isSensitive = try await nodeUseCase.isInheritingSensitivity(node: node)
        } catch {
            MEGALogError("[\(type(of: self))] Error checking if node is inheriting sensitivity: \(error)")
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
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
}

extension HomeSearchResultFileViewModel {
    
    static func < (lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        lhs.name < rhs.name
    }
    
    static func == (lhs: HomeSearchResultFileViewModel, rhs: HomeSearchResultFileViewModel) -> Bool {
        return lhs.handle == rhs.handle
    }
}
