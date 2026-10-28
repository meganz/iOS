import AsyncAlgorithms
import CloudDrive
import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import Search

struct FloatingAddButtonVisibilityDataSource {
    private let nodeSource: NodeSource
    private let nodeBrowserConfig: NodeBrowserConfig
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let searchResultsViewStateProvider: any SearchResultsViewStateProviding
    /// Cached on the first successful lookup so frequent node updates don't keep hitting the SDK
    private let cachedParentNodeHandle = Atomic<HandleEntity?>(wrappedValue: nil)

    init(
        nodeSource: NodeSource,
        nodeBrowserConfig: NodeBrowserConfig,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        searchResultsViewStateProvider: some SearchResultsViewStateProviding
    ) {
        self.nodeUpdatesProvider = nodeUpdatesProvider
        self.nodeBrowserConfig = nodeBrowserConfig
        self.nodeSource = nodeSource
        self.nodeUseCase = nodeUseCase
        self.searchResultsViewStateProvider = searchResultsViewStateProvider
    }

    private func parentNodeHandle() -> HandleEntity? {
        if let handle = cachedParentNodeHandle.wrappedValue {
            return handle
        }
        guard let handle = nodeSource.parentNode?.handle else { return nil }
        cachedParentNodeHandle.mutate { $0 = handle }
        return handle
    }

    private func visibilityValue() -> Bool {
        guard let parentNodeHandle = parentNodeHandle() else { return false }
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: parentNodeHandle)
        return nodeBrowserConfig.isFromViewInFolder != true
        && nodeBrowserConfig.displayMode != .rubbishBin
        && nodeBrowserConfig.displayMode != .backup
        && nodeAccessLevel != .unknown
        && nodeAccessLevel != .read
    }

    private func containsParentNode(_ updatedNodes: [NodeEntity]) -> Bool {
        guard let parentNodeHandle = parentNodeHandle() else { return false }
        return updatedNodes.contains { $0.handle == parentNodeHandle }
    }
}

extension FloatingAddButtonVisibilityDataSource: FloatingAddButtonVisibilityDataSourceProtocol {
    public var floatingButtonVisibility: AnyAsyncSequence<Bool> {
        let parentNodeUpdatesSequence = nodeUpdatesProvider
            .nodeUpdates
            .filter { containsParentNode($0) }
            .map { _ in }
            .prepend(())
            .eraseToAnyAsyncSequence()

        // The parent node is resolved on every emission, as the root node is nil when Cloud Drive is built offline
        return combineLatest(parentNodeUpdatesSequence, searchResultsViewStateProvider.isEditingOrEmpty)
            .map { _, isEditingOrEmpty in !isEditingOrEmpty && visibilityValue() }
            .removeDuplicates()
            .eraseToAnyAsyncSequence()
    }
}
