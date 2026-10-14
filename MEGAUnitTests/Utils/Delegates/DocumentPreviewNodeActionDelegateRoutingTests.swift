import Foundation
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGASdk
import Testing
import UIKit

@MainActor
struct DocumentPreviewNodeActionDelegateRoutingTests {
    private let presenter = PresenterSpy()
    private let link = "https://example.invalid/file/test#fixture"

    @Test(arguments: [false, true])
    func importNode_usesLegacyBrowserFlagAndAvoidsViewerDismiss(isLink: Bool) {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let routing = RoutingSpy()
        let node = MockNode(handle: 1)
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: isLink, fileLink: nil, isFromSharedItem: false
            ),
            presenter: presenter, wrapped: wrapped, routing: routing
        )

        select(.import, node: node, delegate: sut)

        #expect(routing.calls == [.importNode(handle: 1, isFolderLink: false)])
        #expect(routing.presenter === presenter)
        #expect(presenter.dismissCallCount == 0)
        #expect(wrapped.selectedAction == nil)
    }

    @Test
    func folderDownload_usesAuthorizedNodeInsteadOfGenericDownload() {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: true, fileLink: nil, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(.download, node: MockNode(handle: 1), delegate: sut)

        #expect(routing.calls == [.folderDownload(handles: [1])])
        #expect(wrapped.selectedAction == nil)
    }

    @Test
    func fileDownload_usesOriginalLinkInsteadOfGenericDownload() {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: true, fileLink: link, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(.download, node: MockNode(handle: 1), delegate: sut)

        #expect(routing.calls == [.fileDownload(link: link)])
        #expect(wrapped.selectedAction == nil)
    }

    @Test(arguments: [false, true])
    func sendToChat_linkContextSelectsNodeOrOriginalURL(isFileLink: Bool) {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let fileLink = isFileLink ? link : nil
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: true, fileLink: fileLink, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(.sendToChat, node: MockNode(handle: 1), delegate: sut)

        #expect(routing.calls == [.sendToChat(handle: 1, fileLink: fileLink)])
        #expect(wrapped.selectedAction == nil)
    }

    @Test(arguments: [MegaNodeActionType.shareLink, .manageLink], [false, true])
    func fileLinkSharing_usesOriginalLinkAndMoreSender(
        action: MegaNodeActionType,
        usesBarItem: Bool
    ) {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sender: AnyObject = usesBarItem ? UIBarButtonItem() : UIView()
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: true, fileLink: link, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(action, node: MockNode(handle: 1), delegate: sut, sender: sender)

        #expect(routing.calls == [.shareFileLink(link: link)])
        #expect(routing.presenter === presenter)
        #expect((routing.sender as AnyObject?) === sender)
        #expect(wrapped.selectedAction == nil)
    }

    @Test(arguments: [MegaNodeActionType.shareLink, .manageLink])
    func folderLinkSharing_remainsWithGenericDelegate(action: MegaNodeActionType) {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: true, fileLink: nil, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(action, node: MockNode(handle: 1), delegate: sut)

        #expect(wrapped.selectedAction == action)
        #expect(routing.calls.isEmpty)
    }

    @Test(arguments: [
        MegaNodeActionType.download, .sendToChat, .shareLink, .manageLink, .removeLink
    ])
    func accountActions_remainWithGenericDelegate(action: MegaNodeActionType) {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sut = makeSUT(
            context: DocumentPreviewContext(
                isLink: false, fileLink: nil, isFromSharedItem: false
            ),
            wrapped: wrapped, routing: routing
        )

        select(action, node: MockNode(handle: 1), delegate: sut)

        #expect(wrapped.selectedAction == action)
        #expect(routing.calls.isEmpty)
    }

    @Test
    func chatDownload_forwardsToChatConfiguredGenericDelegate() {
        let routing = RoutingSpy()
        let wrapped = ActionSpy()
        let sut = makeSUT(
            context: DocumentPreviewContext(chatId: 11, messageId: 22),
            wrapped: wrapped, routing: routing
        )

        select(.download, node: MockNode(handle: 1), delegate: sut)

        #expect(wrapped.selectedAction == .download)
        #expect(routing.calls.isEmpty)
    }

    @Test
    func info_suppliesDocumentDelegateToNodeInfoFactory() {
        let presenter = PresenterSpy()
        let wrapped = ActionSpy()
        let nodeInfo = UIViewController()
        var receivedNode: MEGANode?
        var receivedDelegate: (any NodeInfoViewControllerDelegate)?
        let sut = DocumentPreviewNodeActionDelegate(
            wrapping: wrapped, presenter: presenter,
            context: DocumentPreviewContext(
                isLink: false, fileLink: nil, isFromSharedItem: false
            ),
            linkActions: RoutingSpy(),
            makeNodeInfo: { node, delegate in
                receivedNode = node
                receivedDelegate = delegate
                return nodeInfo
            },
            analyticsSource: .node
        )
        let node = MockNode(handle: 1)

        select(.info, node: node, delegate: sut)

        #expect(receivedNode === node)
        #expect((receivedDelegate as AnyObject?) === sut)
        #expect(presenter.presentedController === nodeInfo)
        #expect(wrapped.selectedAction == nil)
    }

    @Test
    func interceptedActions_keepSharedMenuItemEvents() {
        let fileLink = DocumentPreviewContext(isLink: true, fileLink: link, isFromSharedItem: false)
        let folderLink = DocumentPreviewContext(isLink: true, fileLink: nil, isFromSharedItem: false)
        let node = DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false)
        let cases: [(MegaNodeActionType, DocumentPreviewContext, (any EventIdentifier) -> Bool)] = [
            (.download, fileLink, { $0 is CloudDriveDownloadMenuItemEvent }),
            (.download, folderLink, { $0 is CloudDriveDownloadMenuItemEvent }),
            (.shareLink, fileLink, { $0 is CloudDriveShareLinkMenuItemEvent }),
            (.manageLink, fileLink, { $0 is CloudDriveShareLinkMenuItemEvent }),
            (.info, node, { $0 is CloudDriveInfoMenuItemEvent })
        ]
        for (action, context, isExpectedEvent) in cases {
            let tracker = MockTracker()
            let sut = makeSUT(context: context, wrapped: ActionSpy(), routing: RoutingSpy(), tracker: tracker)

            select(action, node: MockNode(handle: 1), delegate: sut)

            #expect(tracker.trackedEventIdentifiers.count == 1, "action \(action.rawValue)")
            #expect(tracker.trackedEventIdentifiers.first.map(isExpectedEvent) == true, "action \(action.rawValue)")
        }
    }

    private func makeSUT(
        context: DocumentPreviewContext,
        presenter: PresenterSpy? = nil,
        wrapped: ActionSpy,
        routing: RoutingSpy,
        tracker: MockTracker = MockTracker()
    ) -> DocumentPreviewNodeActionDelegate {
        DocumentPreviewNodeActionDelegate(
            wrapping: wrapped, presenter: presenter ?? self.presenter,
            context: context, linkActions: routing, tracker: tracker,
            analyticsSource: .node
        )
    }

    private func select(
        _ action: MegaNodeActionType,
        node: MEGANode,
        delegate: DocumentPreviewNodeActionDelegate,
        sender: Any = "sender"
    ) {
        let controller = NodeActionViewController(
            node: node, delegate: delegate, displayMode: .nodeInfo,
            viewMode: .thumbnail, isBackupNode: false,
            containsMediaFiles: false, sender: sender
        )
        delegate.nodeAction(controller, didSelect: action, for: node, from: sender)
    }

    private final class RoutingSpy: DocumentPreviewLinkActionRouting {
        enum Call: Equatable {
            case importNode(handle: UInt64, isFolderLink: Bool)
            case folderDownload(handles: [UInt64])
            case fileDownload(link: String)
            case shareFileLink(link: String)
            case sendToChat(handle: UInt64, fileLink: String?)
        }

        var calls: [Call] = []
        var presenter: UIViewController?
        var sender: Any?

        func importNode(_ node: MEGANode, isFolderLink: Bool, from presenter: UIViewController) {
            calls.append(.importNode(handle: node.handle, isFolderLink: isFolderLink))
            self.presenter = presenter
        }

        func downloadFolderLinkNodes(_ nodes: [MEGANode], from presenter: UIViewController) {
            calls.append(.folderDownload(handles: nodes.map(\.handle)))
            self.presenter = presenter
        }

        func downloadFileLink(_ link: String, from presenter: UIViewController) {
            calls.append(.fileDownload(link: link))
            self.presenter = presenter
        }

        func shareFileLink(_ link: String, from presenter: UIViewController, sender: Any) {
            calls.append(.shareFileLink(link: link))
            self.presenter = presenter
            self.sender = sender
        }

        func sendToChat(_ node: MEGANode, fileLink: String?, from presenter: UIViewController) {
            calls.append(.sendToChat(handle: node.handle, fileLink: fileLink))
            self.presenter = presenter
        }
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
        var dismissCallCount = 0
        var presentedController: UIViewController?

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            presentedController = viewControllerToPresent
            completion?()
        }

        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            dismissCallCount += 1
            completion?()
        }
    }
}
