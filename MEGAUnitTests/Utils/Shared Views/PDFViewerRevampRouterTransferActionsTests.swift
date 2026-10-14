import Foundation
@testable import MEGA
import MEGAAppSDKRepoMock
@testable import MEGAPDFViewer
import Testing
import UIKit

@MainActor
struct PDFViewerRevampRouterTransferActionsTests {
    private let fileURL = URL(fileURLWithPath: "/tmp/offline-fixture.pdf")

    enum EntryPoint: CaseIterable {
        case offline
        case cachedNode
        case fileLinkWithoutNode
        case folderLinkWithoutNode
        case chatWithoutNode
        case cachedChatNode

        var expectedAction: PDFViewerTrailingAction {
            switch self {
            case .offline: .download
            case .cachedNode, .cachedChatNode: .more
            case .fileLinkWithoutNode, .folderLinkWithoutNode, .chatWithoutNode: .none
            }
        }
    }

    @Test(arguments: EntryPoint.allCases)
    func localEntryPoint_selectsTrailingActionFromProductionContext(entryPoint: EntryPoint) throws {
        let node = entryPoint == .cachedNode || entryPoint == .cachedChatNode
            ? MockNode(handle: 1) : nil
        let context: DocumentPreviewContext
        switch entryPoint {
        case .fileLinkWithoutNode:
            context = DocumentPreviewContext(
                isLink: true, fileLink: "https://mega.nz/file/fixture",
                isFromSharedItem: false
            )
        case .folderLinkWithoutNode:
            context = DocumentPreviewContext(isLink: true, fileLink: nil, isFromSharedItem: false)
        case .chatWithoutNode, .cachedChatNode:
            context = DocumentPreviewContext(chatId: 1, messageId: 2)
        case .offline, .cachedNode:
            context = DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false)
        }
        let routed = try makeRoutedViewer(node: node, context: context)
        let dependency = routed.dependency

        let action = PDFViewerViewModel.TrailingActionUseCase().action(
            source: dependency.pdfDocumentSource,
            context: dependency.actionContext,
            hasMoreAction: dependency.moreMenuDependencies != nil,
            hasDownloadAction: dependency.downloadDependencies != nil
        )

        #expect(action == entryPoint.expectedAction)
    }

    @Test
    func routedDownload_forwardsExistingURLAndBothAnchorsUntilPresentationCompletes() throws {
        let routed = try makeRoutedViewer(
            node: nil,
            context: DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false)
        )
        let anchor = UIView()
        let barItem = UIBarButtonItem()
        let dependencies = try #require(routed.dependency.downloadDependencies)
        let callbacks = dependencies.anchorReadyCallbacks
        let action = dependencies.onTapped
        var completed = 0
        callbacks.onViewReady(anchor)
        callbacks.onBarItemReady(barItem)

        action { completed += 1 }

        #expect(routed.activity.fileURL == fileURL)
        #expect(routed.activity.presenter === routed.presenter)
        #expect(routed.activity.anchor === anchor)
        #expect(routed.activity.barItem === barItem)
        #expect(completed == 0)
        routed.activity.onPresented?()
        #expect(completed == 1)
    }

    @Test
    func download_restoresToolbarOnlyAfterNativePresentationCompletes() {
        let presenter = PresenterSpy()
        var completed = 0

        PDFViewerActivityPresenter().present(
            fileURL: fileURL, from: presenter, anchor: nil, barItem: nil,
            onPresented: { completed += 1 }
        )

        #expect(presenter.activity != nil)
        #expect(completed == 0)
        presenter.onPresented?()
        #expect(completed == 1)
    }

    @Test
    func download_whileAnotherControllerIsPresented_completesWithoutPresenting() {
        let presenter = PresenterSpy()
        presenter.existingPresentation = UIViewController()
        var completed = 0

        PDFViewerActivityPresenter().present(
            fileURL: fileURL, from: presenter, anchor: nil, barItem: nil,
            onPresented: { completed += 1 }
        )

        #expect(presenter.activity == nil)
        #expect(completed == 1)
    }

    @Test
    func download_afterPresenterDisappears_completesWithoutPresenting() {
        var completed = 0

        PDFViewerActivityPresenter().present(
            fileURL: fileURL, from: nil, anchor: nil, barItem: nil,
            onPresented: { completed += 1 }
        )

        #expect(completed == 1)
    }

    @Test
    func download_withoutLocalURL_completesWithoutPresenting() {
        let presenter = PresenterSpy()
        var completed = 0

        PDFViewerActivityPresenter().present(
            fileURL: nil, from: presenter, anchor: nil, barItem: nil,
            onPresented: { completed += 1 }
        )

        #expect(presenter.activity == nil)
        #expect(completed == 1)
    }

    @Test(.enabled {
        await MainActor.run { UIDevice.current.userInterfaceIdiom == .pad }
    })
    func download_attachedAnchor_configuresNativePopover() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let anchor = UIView(frame: CGRect(x: 20, y: 30, width: 36, height: 44))
        window.addSubview(anchor)
        let presenter = PresenterSpy()

        PDFViewerActivityPresenter().present(
            fileURL: fileURL, from: presenter, anchor: anchor, barItem: nil,
            onPresented: nil
        )

        let popover = presenter.activity?.popoverPresentationController
        #expect(popover?.sourceView === anchor)
        #expect(popover?.sourceRect == anchor.bounds)
    }

    enum InvalidAnchor: CaseIterable {
        case missing
        case detached
        case zeroSized
    }

    @Test(.enabled {
        await MainActor.run { UIDevice.current.userInterfaceIdiom == .pad }
    }, arguments: InvalidAnchor.allCases)
    func download_invalidAnchor_fallsBackToCenteredPopover(invalidAnchor: InvalidAnchor) {
        let presenter = PresenterSpy()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let anchor: UIView?
        switch invalidAnchor {
        case .missing:
            anchor = nil
        case .detached:
            anchor = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 44))
        case .zeroSized:
            let view = UIView()
            window.addSubview(view)
            anchor = view
        }

        PDFViewerActivityPresenter().present(
            fileURL: fileURL, from: presenter, anchor: anchor, barItem: nil,
            onPresented: nil
        )

        let popover = presenter.activity?.popoverPresentationController
        #expect(popover?.sourceView === presenter.view)
        #expect(popover?.sourceRect == CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 0,
            height: 0
        ))
        #expect(popover?.permittedArrowDirections == [])
    }

    @Test(.enabled {
        await MainActor.run { UIDevice.current.userInterfaceIdiom == .pad }
    })
    func linkSharing_attachedViewSender_configuresNativePopover() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let anchor = UIView(frame: CGRect(x: 20, y: 30, width: 36, height: 44))
        window.addSubview(anchor)
        let presenter = PresenterSpy()

        PDFViewerActivityPresenter().presentLink(
            "https://example.invalid/file/test#fixture", from: presenter, sender: anchor
        )

        #expect(presenter.activity != nil)
        let popover = presenter.activity?.popoverPresentationController
        #expect(popover?.sourceView === anchor)
        #expect(popover?.sourceRect == anchor.bounds)
    }

    @Test(.enabled {
        await MainActor.run { UIDevice.current.userInterfaceIdiom == .pad }
    })
    func linkSharing_invalidSender_usesCenteredPopover() {
        let presenter = PresenterSpy()

        PDFViewerActivityPresenter().presentLink(
            "https://example.invalid/file/test#fixture", from: presenter, sender: "sender"
        )

        #expect(presenter.activity != nil)
        let popover = presenter.activity?.popoverPresentationController
        #expect(popover?.sourceView === presenter.view)
        #expect(popover?.sourceRect == CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 0,
            height: 0
        ))
        #expect(popover?.permittedArrowDirections == [])
    }

    private func makeRoutedViewer(
        node: MockNode?,
        context: DocumentPreviewContext
    ) throws -> (dependency: PDFViewerView.Dependency, presenter: PresenterSpy, activity: ActivitySpy) {
        let presenter = PresenterSpy()
        let activity = ActivitySpy()
        var dependency: PDFViewerView.Dependency?
        let navigationController = PDFViewerRevampRouter.makeViewController(
            fileName: fileURL.lastPathComponent, pdfDocumentSource: .local(fileURL),
            node: node, context: context, lastPageUseCase: LastPageStub(),
            activityPresenter: activity,
            viewerFactory: {
                dependency = $0
                return presenter
            }
        )
        #expect((navigationController as? UINavigationController)?.topViewController === presenter)
        return (try #require(dependency), presenter, activity)
    }

    private struct LastPageStub: PDFViewerLastPageUseCaseProtocol {
        func documentIdentifierForLastViewedPageIndex(forDocumentAt url: URL) async -> String? { nil }
        func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? { nil }
        func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {}
    }

    private final class ActivitySpy: PDFViewerActivityPresenting {
        var fileURL: URL?
        var presenter: UIViewController?
        var anchor: UIView?
        var barItem: UIBarButtonItem?
        var onPresented: (@MainActor () -> Void)?

        func presentLink(_ link: String, from presenter: UIViewController, sender: Any) {
        }

        func present(
            fileURL: URL?,
            from presenter: UIViewController?,
            anchor: UIView?,
            barItem: UIBarButtonItem?,
            onPresented: (@MainActor () -> Void)?
        ) {
            self.fileURL = fileURL
            self.presenter = presenter
            self.anchor = anchor
            self.barItem = barItem
            self.onPresented = onPresented
        }
    }

    private final class PresenterSpy: UIViewController {
        var existingPresentation: UIViewController?
        var activity: UIActivityViewController?
        var onPresented: (() -> Void)?
        override var presentedViewController: UIViewController? { existingPresentation }

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            activity = viewControllerToPresent as? UIActivityViewController
            onPresented = completion
        }
    }
}
