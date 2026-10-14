import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGASdk
import Testing
import UIKit

@MainActor
struct DocumentPreviewLinkActionRouterTests {
    @Test
    func importNode_startsExistingRouterWithoutDismissingPreview() {
        let node = MockNode(handle: 1)
        let presenter = UIViewController()
        let importRouter = MockImportLinkRouter()
        var receivedFolderFlag: Bool?
        var receivedNodes: [MEGANode] = []
        var receivedPresenter: UIViewController?
        var receivedDismissFlag: Bool?
        let sut = DocumentPreviewLinkActionRouter(importRouterFactory: { isFolderLink, nodes, presenter, dismissBeforePresent in
            receivedFolderFlag = isFolderLink
            receivedNodes = nodes
            receivedPresenter = presenter
            receivedDismissFlag = dismissBeforePresent
            return importRouter
        })

        sut.importNode(node, isFolderLink: false, from: presenter)

        #expect(receivedFolderFlag == false)
        #expect(receivedNodes.count == 1)
        #expect(receivedNodes.first === node)
        #expect(receivedPresenter === presenter)
        #expect(receivedDismissFlag == false)
        #expect(importRouter.startCalled == 1)
    }

    @Test(arguments: [false, true])
    func shareFileLink_forwardsOriginalLinkPresenterAndSender(usesBarItem: Bool) {
        let link = "https://example.invalid/file/test#fixture"
        let presenter = UIViewController()
        let sender: AnyObject = usesBarItem ? UIBarButtonItem() : UIView()
        let activity = ActivitySpy()
        let sut = DocumentPreviewLinkActionRouter(activityPresenter: activity)

        sut.shareFileLink(link, from: presenter, sender: sender)

        #expect(activity.link == link)
        #expect(activity.presenter === presenter)
        #expect((activity.sender as AnyObject?) === sender)
    }

    private final class ActivitySpy: PDFViewerActivityPresenting {
        var link: String?
        var presenter: UIViewController?
        var sender: Any?

        func presentLink(_ link: String, from presenter: UIViewController, sender: Any) {
            self.link = link
            self.presenter = presenter
            self.sender = sender
        }

        func present(
            fileURL: URL?,
            from presenter: UIViewController?,
            anchor: UIView?,
            barItem: UIBarButtonItem?,
            onPresented: (@MainActor () -> Void)?
        ) {
        }
    }
}
