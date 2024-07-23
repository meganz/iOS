import MEGADomain
import MEGASwift

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
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol

    init(
        config: NodeBrowserConfig,
        contextMenuManager: ContextMenuManager,
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory,
        nodeSensitivityChecker: some NodeSensitivityChecking,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.config = config
        self.contextMenuManager = contextMenuManager
        self.contextMenuConfigFactory = contextMenuConfigFactory
        self.nodeSensitivityChecker = nodeSensitivityChecker
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.nodeUseCase = nodeUseCase
    }

    func makeNodeBrowserContextMenuViewFactory(
        nodeSource: NodeSource,
        viewMode: ViewModePreferenceEntity,
        isSelectionHidden: Bool,
        sortOrder: MEGADomain.SortOrderEntity
    ) -> AnyAsyncSequence<NodeBrowserContextMenuViewFactory> {
        var currentState: NodeBrowserContextMenuState = .initial
        return AsyncStream {
            defer {
                switch currentState {
                case .initial:
                    currentState = .sensitivityCheck
                case .sensitivityCheck:
                    currentState = .done
                case .done:
                    break
                }
            }

            switch currentState {
            case .initial:
                return NodeBrowserContextMenuViewFactory(
                    makeNavItemsFactory: makeNavItemsFactory(
                        nodeSource: nodeSource,
                        isHidden: nil,
                        viewMode: viewMode,
                        isSelectionHidden: isSelectionHidden,
                        sortOrder: sortOrder
                    )
                )
            case .sensitivityCheck:
                let isHidden = await nodeSensitivityChecker.evaluateNodeSensitivity(
                    for: nodeSource,
                    displayMode: config.displayMode ?? .cloudDrive,
                    isFromSharedItem: config.isFromSharedItem ?? false
                )

                guard let isHidden else { return nil }

                return NodeBrowserContextMenuViewFactory(
                    makeNavItemsFactory: makeNavItemsFactory(
                        nodeSource: nodeSource,
                        isHidden: isHidden,
                        viewMode: viewMode,
                        isSelectionHidden: isSelectionHidden,
                        sortOrder: sortOrder
                    )
                )
            case .done:
                return nil
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
