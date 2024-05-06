import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift

@objc final class NodeTableViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    let hasThumbnail: Bool
    
    private let nodes: [NodeEntity]
    private let flavour: NodeTableViewCellFlavor
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var task: Task<Void, Never>?
    
    init(nodes: [NodeEntity],
         flavour: NodeTableViewCellFlavor,
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.nodes = nodes
        self.hasThumbnail = [
            [.flavorCloudDrive].contains(flavour),
            nodes.count == 1,
            nodes.first?.hasThumbnail ?? false
        ].allSatisfy { $0 }
        self.flavour = flavour
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    deinit {
        task?.cancel()
        task = nil
    }
    
    @discardableResult
    func configureCell() -> Task<Void, Never> {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await applySensitiveConfiguration(for: nodes)
        }
        self.task = task
        return task
    }
    
    @MainActor
    private func applySensitiveConfiguration(for nodes: [NodeEntity]) async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              [.flavorRecentAction, .explorerView, .flavorCloudDrive].contains(flavour)
        else {
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
            MEGALogError("Error checking if node is inheriting sensitivity: \(error)")
        }
    }
}
