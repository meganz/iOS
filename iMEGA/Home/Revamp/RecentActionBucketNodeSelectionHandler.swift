import MEGAAppPresentation
import MEGADomain
import UIKit

struct RecentActionBucketNodeSelectionHandler: NodeSelectionHandling {
    private let nodeRouter: any NodeRouting
    
    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }
    
    func handle(selection: NodeSelection) {
        nodeRouter.didTapNode(
            nodeHandle: selection.handle,
            allNodeHandles: selection.siblings.isEmpty ? nil : selection.siblings,
            displayMode: .recents,
            isFromSharedItem: false,
            warningViewModel: nil
        )
    }
}

struct RecentActionBucketLocationHandler: NodeLocationHandling {
    private let nodeUseCase: any NodeUseCaseProtocol

    init(nodeUseCase: some NodeUseCaseProtocol) {
        self.nodeUseCase = nodeUseCase
    }

    func showInLocation(of nodeHandle: HandleEntity) {
        guard let node = nodeUseCase.nodeForHandle(nodeHandle),
              let mainTBC = UIApplication.mainTabBarRootViewController() as? MainTabBarController
        else { return }

        if let sharedRoot = sharedItemsRoot(for: node) {
            showInSharedItems(node, sharedRoot: sharedRoot, mainTBC: mainTBC)
        } else {
            showInCloudDrive(node, mainTBC: mainTBC)
        }
    }

    // MARK: - Cloud Drive

    private func showInCloudDrive(_ node: NodeEntity, mainTBC: MainTabBarController) {
        mainTBC.selectedIndex = TabManager.driveTabIndex()
        guard let navigationController = mainTBC.selectedViewController as? UINavigationController else { return }
        navigationController.popToRootViewController(animated: false)

        // A node with no parent is the root itself, the popped-to root screen is
        // the location, so there is nothing to highlight.
        guard let parent = nodeUseCase.parentForHandle(node.handle) else { return }

        let destinationViewController: NewCloudDriveViewController?
        if nodeUseCase.rootNode()?.handle == parent.handle {
            // The location is the account root, already shown by the tab's root
            // screen, highlight the node there instead of pushing a duplicate.
            destinationViewController = navigationController.viewControllers.first as? NewCloudDriveViewController
        } else {
            destinationViewController = pushCloudDriveHierarchy(
                to: parent,
                stopAtHandle: nodeUseCase.rootNode()?.handle,
                isFromSharedItem: false,
                in: navigationController
            )
        }

        destinationViewController?.scrollToAndHighlight(handle: node.handle)
    }

    // MARK: - Shared Items

    private func showInSharedItems(_ node: NodeEntity, sharedRoot: NodeEntity, mainTBC: MainTabBarController) {
        mainTBC.selectedIndex = TabManager.menuTabIndex()
        guard let navigationController = mainTBC.selectedViewController as? UINavigationController,
              let menuPresenter = navigationController as? (any AccountMenuItemsNavigating)
        else { return }

        navigationController.popToRootViewController(animated: false)
        menuPresenter.showSharedItems()

        guard let sharedItemsViewController = navigationController.topViewController as? SharedItemsViewController else { return }
        sharedItemsViewController.loadViewIfNeeded()
        sharedItemsViewController.selectSegment(UInt(sharedItemsTab(for: sharedRoot).rawValue))

        if node.handle == sharedRoot.handle {
            // The node is a share root, listed directly in Shared Items.
            sharedItemsViewController.scrollToAndHighlightNode(handle: node.handle)
            return
        }

        let parent = nodeUseCase.parentForHandle(node.handle) ?? sharedRoot
        let destinationViewController = pushCloudDriveHierarchy(
            to: parent,
            stopAtHandle: nodeUseCase.parentForHandle(sharedRoot.handle)?.handle,
            isFromSharedItem: true,
            in: navigationController
        )
        destinationViewController?.scrollToAndHighlight(handle: node.handle)
    }

    // MARK: - Helpers

    /// Pushes the chain of folders leading down to target `folder` so the user lands inside
    /// the target `folder`, with every intermediate folder sitting in the back stack
    ///
    /// - Parameters:
    ///   - folder: The deepest folder to open. The chain is built by walking up from here.
    ///   - stopAtHandle: Handle to stop the upward walk at, *exclusive* — the node with
    ///     this handle is not pushed. Typically the root already shown by the tab, so it
    ///     isn't duplicated. `nil` walks all the way to the top.
    ///   - isFromSharedItem: Whether the destination lives under Shared Items; drives the
    ///     browser config so the pushed screens render in the shared-item context.
    ///   - navigationController: The stack to push the folder screens onto.
    /// - Returns: The deepest pushed Cloud Drive screen (the one to highlight on), or
    ///   `nil` if there was nothing to push.
    private func pushCloudDriveHierarchy(
        to folder: NodeEntity,
        stopAtHandle: HandleEntity?,
        isFromSharedItem: Bool,
        in navigationController: UINavigationController
    ) -> NewCloudDriveViewController? {
        var chain: [NodeEntity] = []
        var current: NodeEntity? = folder
        var visitedHandles = Set<HandleEntity>()

        while let node = current, node.handle != stopAtHandle, !visitedHandles.contains(node.handle) {
            visitedHandles.insert(node.handle)
            chain.append(node)
            current = nodeUseCase.parentForHandle(node.handle)
        }
        chain.reverse()

        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let config = NodeBrowserConfig(displayMode: .cloudDrive, isFromSharedItem: isFromSharedItem)

        let folderViewControllers = chain.compactMap { node -> UIViewController? in
            guard let viewController = factory.buildBare(parentNode: node, config: config) else { return nil }
            viewController.navigationItem.backButtonTitle = ""
            return viewController
        }
        // Covers both an empty `chain` and a `buildBare` that produced nothing — either
        // way there is no folder to push and nothing to highlight.
        guard !folderViewControllers.isEmpty else { return nil }

        navigationController.setViewControllers(
            navigationController.viewControllers + folderViewControllers,
            animated: true
        )
        return folderViewControllers.last as? NewCloudDriveViewController
    }

    private func sharedItemsRoot(for node: NodeEntity) -> NodeEntity? {
        var currentNode: NodeEntity? = node
        var sharedRoot: NodeEntity?
        var visitedHandles = Set<HandleEntity>()

        while let node = currentNode, !visitedHandles.contains(node.handle) {
            visitedHandles.insert(node.handle)
            if isSharedItemsRoot(node) {
                sharedRoot = node
            }
            currentNode = nodeUseCase.parentForHandle(node.handle)
        }

        return sharedRoot
    }

    private func isSharedItemsRoot(_ node: NodeEntity) -> Bool {
        node.isInShare || node.isOutShare
    }

    private func sharedItemsTab(for node: NodeEntity) -> SharedItemsTabSelection {
        node.isInShare ? .incoming : .outgoing
    }
}
