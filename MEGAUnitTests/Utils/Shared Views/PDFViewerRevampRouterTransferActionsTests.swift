import Foundation
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomainMock
@testable import MEGAPDFViewer
import Testing
import Transfer
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

    @Test(arguments: [PDFViewerAnalyticsSource.offline, .unknown])
    func downloadIntent_preservesSourceAndDoesNotBecomeCompletion(source: PDFViewerAnalyticsSource) {
        let tracker = MockTracker()
        let presenter = PresenterSpy()
        PDFViewerRevampRouter.requestDownload(
            fileURL: fileURL, from: presenter, anchor: nil, barItem: nil,
            source: source, trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker),
            onPresented: nil
        )
        #expect(tracker.trackedEventIdentifiers.count == 1)
        let event = tracker.trackedEventIdentifiers.first as? PdfViewerDownloadRequestedEvent
        #expect(event?.info["source"] as? String == source.rawValue)
        presenter.onPresented?()
        presenter.activity?.completionWithItemsHandler?(nil, false, nil, nil)
        #expect(tracker.trackedEventIdentifiers.count == 1)
    }

    @Test(arguments: [true, false])
    func routedViewer_offlineSourceDrivesFileOpenAndDownloadAttribution(isOffline: Bool) throws {
        let tracker = MockTracker()
        var dependency: PDFViewerView.Dependency?
        _ = PDFViewerRevampRouter.makeViewController(
            fileName: fileURL.lastPathComponent, pdfDocumentSource: .local(fileURL),
            node: isOffline ? nil : MockNode(handle: 1),
            context: DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false),
            explicitSource: isOffline ? .offline : nil,
            lastPageUseCase: LastPageStub(),
            activityPresenter: ActivitySpy(),
            trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker),
            viewerFactory: {
                dependency = $0
                return PresenterSpy()
            }
        )
        let viewer = try #require(dependency)

        viewer.onViewerPresented()
        viewer.downloadDependencies?.onTapped(nil)

        let fileOpens = tracker.trackedEventIdentifiers.filter { $0 is FileOpenEvent }
        #expect(fileOpens.count == (isOffline ? 1 : 0))
        let download = tracker.trackedEventIdentifiers
            .compactMap { $0 as? PdfViewerDownloadRequestedEvent }.first
        #expect(download?.info["source"] as? String == (isOffline ? "offline" : "node"))
    }

    @Test func downloadWithoutFile_emitsNoIntentAndRestoresAnimation() {
        let tracker = MockTracker()
        var restored = false
        PDFViewerRevampRouter.requestDownload(
            fileURL: nil, from: PresenterSpy(), anchor: nil, barItem: nil,
            source: .unknown, trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker),
            onPresented: { restored = true }
        )
        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(restored)
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

@MainActor
@Suite(.serialized)
struct PDFViewerRevampLifecycleTests {
    @Test func modalDismissal_tracksConfirmedExitOnce() async throws {
        let tracker = MockTracker()
        let (window, presenter, fileURL) = try makePresentingWindow()
        defer {
            window.isHidden = true
            try? FileManager.default.removeItem(at: fileURL)
        }
        _ = try await presentViewer(fileURL: fileURL, tracker: tracker, from: presenter)
        #expect(tracker.trackedEventIdentifiers.filter { $0 is PdfViewerScreenEvent }.count == 1)
        #expect(!tracker.trackedEventIdentifiers.contains { $0 is PdfViewerClosedEvent })
        var dismissed = false
        presenter.dismiss(animated: false) { dismissed = true }
        for _ in 0..<30 where !dismissed { try await Task.sleep(for: .milliseconds(100)) }
        try #require(dismissed, "UIKit did not complete dismissal")
        try #require(presenter.presentedViewController == nil, "Viewer is still presented")
        #expect(tracker.trackedEventIdentifiers.filter { $0 is PdfViewerClosedEvent }.count == 1)
    }

    @Test func modalDismissalWithoutRetainedViewer_tracksExitOnce() async throws {
        let tracker = MockTracker()
        let (window, presenter, fileURL) = try makePresentingWindow()
        defer {
            window.isHidden = true
            try? FileManager.default.removeItem(at: fileURL)
        }
        weak var releasedNavigation: UINavigationController?
        var dismissed = false
        do {
            let navigation = try await presentViewer(fileURL: fileURL, tracker: tracker, from: presenter)
            releasedNavigation = navigation
            presenter.dismiss(animated: false) { dismissed = true }
        }
        for _ in 0..<30 where !dismissed { try await Task.sleep(for: .milliseconds(100)) }
        try #require(dismissed, "UIKit did not complete dismissal")
        try #require(presenter.presentedViewController == nil, "Viewer is still presented")
        #expect(releasedNavigation == nil)
        #expect(tracker.trackedEventIdentifiers.filter { $0 is PdfViewerClosedEvent }.count == 1)
    }

    @Test func coverPresentedAndDismissed_keepsOneScreenAndNoClose() async throws {
        let tracker = MockTracker()
        let (window, presenter, fileURL) = try makePresentingWindow()
        defer {
            window.isHidden = true
            try? FileManager.default.removeItem(at: fileURL)
        }
        let navigation = try await presentViewer(fileURL: fileURL, tracker: tracker, from: presenter)
        let cover = UIViewController()
        cover.modalPresentationStyle = .fullScreen
        var covered = false
        navigation.present(cover, animated: false) { covered = true }
        for _ in 0..<30 where !covered { try await Task.sleep(for: .milliseconds(100)) }
        var uncovered = false
        cover.dismiss(animated: false) { uncovered = true }
        for _ in 0..<30 where !uncovered { try await Task.sleep(for: .milliseconds(100)) }
        try #require(uncovered, "UIKit did not complete the cover's dismissal")
        #expect(tracker.trackedEventIdentifiers.filter { $0 is PdfViewerScreenEvent }.count == 1)
        #expect(!tracker.trackedEventIdentifiers.contains { $0 is PdfViewerClosedEvent })
        presenter.dismiss(animated: false)
    }

    private func makePresentingWindow() throws -> (UIWindow, UIViewController, URL) {
        SharedTransferIndicator.configure()
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 400, height: 700)).pdfData { context in
            context.beginPage()
            "Analytics fixture".draw(at: CGPoint(x: 30, y: 30))
        }
        try data.write(to: fileURL)
        return (window, presenter, fileURL)
    }

    private func presentViewer(
        fileURL: URL,
        tracker: MockTracker,
        from presenter: UIViewController
    ) async throws -> UINavigationController {
        let viewer = PDFViewerViewController(dependency: .init(
            pdfDocumentSource: .local(fileURL), downloadUseCase: MockDownloadNodeUseCase(),
            lastPageUseCase: LastPageStub(),
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(), node: nil,
            fileName: "fixture.pdf",
            transferIndicatorToolbarFactory: .indicator(), onClose: {},
            trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker)
        ))
        let navigation = UINavigationController(rootViewController: viewer)
        navigation.modalPresentationStyle = .fullScreen
        var presented = false
        presenter.present(navigation, animated: false) { presented = true }
        for _ in 0..<30 where !presented { try await Task.sleep(for: .milliseconds(100)) }
        try #require(presented, "UIKit did not complete presentation")
        return navigation
    }

    private struct LastPageStub: PDFViewerLastPageUseCaseProtocol {
        func documentIdentifierForLastViewedPageIndex(forDocumentAt url: URL) async -> String? { nil }
        func loadLastPageIndex(forDocumentIdentifier documentIdentifier: String) async -> Int? { nil }
        func saveLastPageIndex(_ index: Int, forDocumentIdentifier documentIdentifier: String) async {}
    }
}
