import MEGADomain
import MEGASwift

@MainActor
struct CloudDriveContextMenuFactory {
    private enum NodeBrowserContextMenuState {
        case initial
        case sensitivityCheck
        case done
    }

    private let config: NodeBrowserConfig
    private let contextMenuManager: ContextMenuManager
    private let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    private let nodeSensitivityChecker: any NodeSensitivityChecking
    private let nodeUseCase: any NodeUseCaseProtocol

    init(
        config: NodeBrowserConfig,
        contextMenuManager: ContextMenuManager,
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory,
        nodeSensitivityChecker: some NodeSensitivityChecking,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.config = config
        self.contextMenuManager = contextMenuManager
        self.contextMenuConfigFactory = contextMenuConfigFactory
        self.nodeSensitivityChecker = nodeSensitivityChecker
        self.nodeUseCase = nodeUseCase
    }

    func makeNodeBrowserContextMenuViewFactory(
        nodeSource: NodeSource,
        viewMode: ViewModePreferenceEntity,
        isSelectionHidden: Bool,
        sortOrder: MEGADomain.SortOrderEntity
    ) -> AnyAsyncSequence<NodeBrowserContextMenuViewFactory> {
        AsyncStream { continuation in
            Task {
                let initialFactory = NodeBrowserContextMenuViewFactory(
                    makeNavItemsFactory: makeNavItemsFactory(
                        nodeSource: nodeSource,
                        isHidden: nil,
                        viewMode: viewMode,
                        isSelectionHidden: isSelectionHidden,
                        sortOrder: sortOrder
                    )
                )
                
                continuation.yield(initialFactory)
                
                let isHidden = await nodeSensitivityChecker.evaluateNodeSensitivity(
                    for: nodeSource,
                    displayMode: config.displayMode ?? .cloudDrive,
                    isFromSharedItem: config.isFromSharedItem ?? false
                )

                guard let isHidden else {
                    continuation.finish()
                    return
                }
                
                let withHiddenNodeFactory = NodeBrowserContextMenuViewFactory(
                    makeNavItemsFactory: makeNavItemsFactory(
                        nodeSource: nodeSource,
                        isHidden: isHidden,
                        viewMode: viewMode,
                        isSelectionHidden: isSelectionHidden,
                        sortOrder: sortOrder
                    )
                )
                continuation.yield(withHiddenNodeFactory)
                continuation.finish()
            }
        }
        .eraseToAnyAsyncSequence()
    }

    private func makeNavItemsFactory(
        nodeSource: NodeSource,
        isHidden: Bool?,
        viewMode: ViewModePreferenceEntity,
        isSelectionHidden: Bool,
        sortOrder: MEGADomain.SortOrderEntity
    ) -> NodeBrowserContextMenuViewFactory.MakeNavItemsFactory {
        {
            CloudDriveViewControllerNavItemsFactory(
                nodeSource: nodeSource,
                config: config,
                currentViewMode: viewMode,
                contextMenuManager: contextMenuManager,
                contextMenuConfigFactory: contextMenuConfigFactory,
                nodeUseCase: nodeUseCase,
                isSelectionHidden: isSelectionHidden,
                sortOrder: sortOrder,
                isHidden: isHidden
            )
        }
    }
}
