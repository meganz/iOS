import AsyncAlgorithms
import CloudDrive
import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

struct FloatingAddButtonVisibilityDataSource {
    private let parentNode: NodeEntity?
    private let nodeBrowserConfig: NodeBrowserConfig
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    private let nodeUseCase: any NodeUseCaseProtocol

    init(
        parentNode: NodeEntity?,
        nodeBrowserConfig: NodeBrowserConfig,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.nodeUpdatesProvider = nodeUpdatesProvider
        self.nodeBrowserConfig = nodeBrowserConfig
        self.parentNode = parentNode
        self.nodeUseCase = nodeUseCase
    }

    private func visibilityValue(for node: NodeEntity) -> Bool {
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)
        return nodeBrowserConfig.isFromViewInFolder != true
        && nodeBrowserConfig.displayMode != .rubbishBin
        && nodeBrowserConfig.displayMode != .backup
        && nodeAccessLevel != .unknown
        && nodeAccessLevel != .read
    }

    private func processNodeUpdates(_ updatedNodes: [NodeEntity]) async -> Bool? {
        guard let updatedParentNode = updatedNodes.first(where: { $0.handle == parentNode?.handle }) else {
            return nil
        }
        return visibilityValue(for: updatedParentNode)
    }
}

extension FloatingAddButtonVisibilityDataSource: FloatingAddButtonVisibilityDataSourceProtocol {
    public var floatingButtonVisibility: AnyAsyncSequence<Bool> {
        guard let parentNode else {
            return [false].async.eraseToAnyAsyncSequence()
        }
        return nodeUpdatesProvider
            .nodeUpdates
            .map { await self.processNodeUpdates($0) }
            .compacted()
            .prepend(visibilityValue(for: parentNode))
            .eraseToAnyAsyncSequence()
    }
}
