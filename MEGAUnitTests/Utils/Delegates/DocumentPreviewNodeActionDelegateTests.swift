@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomainMock
import MEGATest
import XCTest

@MainActor
final class DocumentPreviewNodeActionDelegateTests: XCTestCase {
    func testInfo_presentsNodeInfoInsteadOfForwarding() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let node = MockNode(handle: 1)
        let sut = makeSUT(wrapped: wrapped, presenter: presenter)

        sut.nodeAction(actionController(node: node, delegate: sut), didSelect: .info,
                       for: node, from: "sender")

        XCTAssertTrue(presenter.presentedViewController is MEGANavigationController)
        XCTAssertNil(wrapped.selectedAction)
    }

    func testHide_tracksEventAndForwards() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let tracker = MockTracker()
        let node = MockNode(handle: 1)
        let sut = makeSUT(wrapped: wrapped, presenter: presenter, tracker: tracker)

        sut.nodeAction(actionController(node: node, delegate: sut), didSelect: .hide,
                       for: node, from: "sender")

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [DocumentPreviewHideNodeMenuItemEvent()]
        )
        XCTAssertEqual(wrapped.selectedAction, .hide)
    }

    func testMoveToRubbishBin_usesRubbishBinHandler() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let node = MockNode(handle: 1)
        var movedNode: MEGANode?
        let sut = makeSUT(wrapped: wrapped, presenter: presenter, moveToRubbishBin: { movedNode = $0 })

        sut.nodeAction(actionController(node: node, delegate: sut), didSelect: .moveToRubbishBin,
                       for: node, from: "sender")

        XCTAssertEqual(movedNode?.handle, node.handle)
        XCTAssertNil(wrapped.selectedAction)
    }

    func testRestore_dismissesViewerAndRestoresNode() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let node = MockNode(handle: 1)
        var restoredNode: MEGANode?
        let sut = makeSUT(wrapped: wrapped, presenter: presenter, restore: { restoredNode = $0 })

        sut.nodeAction(actionController(node: node, delegate: sut), didSelect: .restore,
                       for: node, from: "sender")

        XCTAssertEqual(presenter.dismissCallCount, 1)
        XCTAssertEqual(restoredNode?.handle, node.handle)
        XCTAssertNil(wrapped.selectedAction)
    }

    func testOtherAction_forwardsToWrappedDelegate() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let node = MockNode(handle: 1)
        let sut = makeSUT(wrapped: wrapped, presenter: presenter)

        sut.nodeAction(actionController(node: node, delegate: sut), didSelect: .download,
                       for: node, from: "sender")

        XCTAssertEqual(wrapped.selectedAction, .download)
        XCTAssertNil(presenter.presentedViewController)
        XCTAssertEqual(presenter.dismissCallCount, 0)
    }

    func testShowParent_dismissesViewerBeforeNavigating() {
        let presenter = PresenterSpy()
        let node = MockNode(handle: 1)
        var dismissedBeforeNavigation = false
        let sut = makeSUT(
            wrapped: ActionSpy(),
            presenter: presenter,
            navigateToParent: { _ in dismissedBeforeNavigation = presenter.dismissCallCount == 1 }
        )
        let nodeInfo = NodeInfoViewController.makeInstance(
            with: NodeInfoViewModel(
                withNode: node,
                nodeUseCase: MockNodeDataUseCase(),
                backupUseCase: MockBackupsUseCase()
            ),
            delegate: nil
        ).nodeInfoViewController

        sut.nodeInfoViewController(nodeInfo, presentParentNode: node)

        XCTAssertTrue(dismissedBeforeNavigation)
    }

    func testMakeNodeActionViewController_usesDocumentPreviewDelegate() {
        let actions = DocumentPreviewNodeActionDelegate.makeNodeActionViewController(
            for: MockNode(handle: 1),
            presenter: UIViewController(),
            context: DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false),
            sender: nil
        )

        XCTAssertTrue(actions.delegate is DocumentPreviewNodeActionDelegate)
    }

    func testIsPreviewingVersion_onlyWhenPresentedFromVersions() {
        XCTAssertTrue(DocumentPreviewNodeActionDelegate.isPreviewingVersion(
            presentingViewController: MEGANavigationController(rootViewController: NodeVersionsViewController())
        ))
        XCTAssertFalse(DocumentPreviewNodeActionDelegate.isPreviewingVersion(
            presentingViewController: MEGANavigationController(rootViewController: UIViewController())
        ))
        XCTAssertFalse(DocumentPreviewNodeActionDelegate.isPreviewingVersion(presentingViewController: nil))
    }

    private func makeSUT(
        wrapped: ActionSpy,
        presenter: PresenterSpy,
        tracker: MockTracker = MockTracker(),
        navigateToParent: @escaping @MainActor (MEGANode) -> Void = { _ in },
        moveToRubbishBin: @escaping @MainActor (MEGANode) -> Void = { _ in },
        restore: @escaping @MainActor (MEGANode) -> Void = { _ in }
    ) -> DocumentPreviewNodeActionDelegate {
        DocumentPreviewNodeActionDelegate(
            wrapping: wrapped,
            presenter: presenter,
            tracker: tracker,
            navigateToParent: navigateToParent,
            moveToRubbishBin: { node, _ in moveToRubbishBin(node) },
            restore: restore
        )
    }

    private func actionController(
        node: MEGANode,
        delegate: DocumentPreviewNodeActionDelegate
    ) -> NodeActionViewController {
        NodeActionViewController(
            node: node,
            delegate: delegate,
            displayMode: .nodeInfo,
            viewMode: .thumbnail,
            isBackupNode: false,
            containsMediaFiles: false,
            sender: "sender"
        )
    }

    private final class ActionSpy: NodeActionViewControllerDelegate {
        var selectedAction: MegaNodeActionType?

        func nodeAction(
            _ nodeAction: NodeActionViewController,
            didSelect action: MegaNodeActionType,
            for node: MEGANode,
            from sender: Any
        ) {
            selectedAction = action
        }
    }

    private final class PresenterSpy: UIViewController {
        private(set) var dismissCallCount = 0
        private var presented: UIViewController?

        override var presentedViewController: UIViewController? { presented }

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            presented = viewControllerToPresent
        }

        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            dismissCallCount += 1
            completion?()
        }
    }
}
