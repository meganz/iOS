import MEGADomain
import UIKit

struct CloudDriveViewControllerNavItemsFactory {
    // Private structure that carries actual button items
    // to enable pure function and testing
    struct NavItems {
        let leftBarButtonItem: UIBarButtonItem?
        let rightNavBarItems: [UIBarButtonItem]

        static let empty = NavItems(
            leftBarButtonItem: nil,
            rightNavBarItems: []
        )
    }

    let nodeSource: NodeSource
    let config: NodeBrowserConfig
    let currentViewMode: ViewModePreferenceEntity
    let contextMenuManager: ContextMenuManager
    let contextMenuConfigFactory: CloudDriveContextMenuConfigFactory
    let nodeUseCase: any NodeUseCaseProtocol
    let isSelectionHidden: Bool

    @MainActor
    func makeNavItems() async -> NavItems {
        guard case let .node(nodeProvider) = nodeSource else {
            return .empty
        }

        let parentNode = nodeProvider()

        let hasMedia = await CloudDriveViewControllerMediaCheckerMode
            .containsSomeMedia
            .makeVisualMediaChecker(nodeSource: nodeSource, nodeUseCase: nodeUseCase)()
        let accessType = await nodeUseCase.nodeAccessLevelAsync(nodeHandle: parentNode?.handle ?? .invalid)

        let menuConfig = contextMenuConfigFactory.contextMenuConfiguration(
            parentNode: parentNode,
            nodeAccessType: accessType,
            currentViewMode: currentViewMode,
            isSelectionHidden: isSelectionHidden,
            showMediaDiscovery: sharedShouldShowMediaDiscoveryContextMenuOption(
                mediaDiscoveryDetectionEnabled: !nodeSource.isRoot,
                hasMediaFiles: hasMedia,
                isFromSharedItem: config.isFromSharedItem == true,
                viewModePreference: currentViewMode

            ),
            sortOrder: .defaultAsc,
            displayMode: config.displayMode?.carriedOverDisplayMode ?? .cloudDrive,
            isFromViewInFolder: config.isFromViewInFolder == true
        )
        guard let menuConfig else {
            return .empty
        }

        guard let menu = contextMenuManager.contextMenu(with: menuConfig) else {
            fatalError("menu should be available")
        }

        let rightNavBarItems = [
            makeAddBarButtonItem(),
            UIBarButtonItem(
                image: UIImage.moreNavigationBar,
                menu: menu
            )
        ]

        let makeLeftBarButtonItem: () -> UIBarButtonItem? = {
            // cancel button needs to be produced here when VC is presented modally
            // to enable dismissal
            nil
        }

        return .init(
            leftBarButtonItem: makeLeftBarButtonItem(),
            rightNavBarItems: rightNavBarItems.compactMap { $0 }
        )
    }

    // MARK: - Private methods.

    private func makeAddBarButtonItem() -> UIBarButtonItem? {
        guard config.isFromViewInFolder != true,
              config.displayMode != .rubbishBin,
              config.displayMode != .backup else {
            return nil
        }

        let addBarMenuConfig = CMConfigEntity(menuType: .menu(type: .uploadAdd), viewMode: currentViewMode)
        let addBarMenu = contextMenuManager.contextMenu(with: addBarMenuConfig)
        return UIBarButtonItem(image: UIImage.navigationbarAdd, menu: addBarMenu)
    }
}
