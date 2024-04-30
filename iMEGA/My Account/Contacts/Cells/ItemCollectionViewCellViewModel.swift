import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@objc final class ItemCollectionViewCellViewModel: NSObject {
        
    @Published private(set) var isSensitive: Bool = false
    let isVideo: Bool
    let hasThumbnail: Bool

    private let node: NodeEntity
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var task: Task<Void, Never>?
    
    init(node: NodeEntity,
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.node = node
        self.hasThumbnail = node.hasThumbnail
        self.isVideo = node.name.fileExtensionGroup.isVideo
        self.nodeUseCase = nodeUseCase
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
            }
            self.task = task
            return task
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
