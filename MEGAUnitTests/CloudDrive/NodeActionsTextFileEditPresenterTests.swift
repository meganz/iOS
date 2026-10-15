@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing
import UIKit

@MainActor
struct NodeActionsTextFileEditPresenterTests {
    private static let overLimit: UInt64 = 100 * 1024 * 1024 + 1

    private static func makeScreen(tracker: MockTracker = MockTracker()) -> MarkdownTextEditorViewController {
        let viewModel = TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: TextFile(fileName: "notes.md"),
            textEditorMode: .view,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            backupsUseCase: MockBackupsUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: NodeEntity(name: "notes.md", handle: 77, isFile: true, size: 10),
            tracker: tracker
        )
        return MarkdownTextEditorViewController(viewModel: viewModel)
    }

    /// A timeout is recorded at the caller, so the failure names the wait, not a later expectation.
    private static func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for _ in 0..<500 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        if !condition() { Issue.record("The condition did not hold within 5 seconds", sourceLocation: sourceLocation) }
    }

    @Test func markdownWithGateOnUsesTheVisibleScreen() async throws {
        let tracker = MockTracker()
        let screen = Self.makeScreen(tracker: tracker)
        let nav = UINavigationController(rootViewController: screen)
        screen.loadViewIfNeeded()
        let node = NodeEntity(name: "notes.md", handle: 1, isFile: true, size: 10)
        #expect(NodeActionsTextFileEditPresenter.presenter(for: node, in: nav, isMarkdownEditorEnabled: true) === screen)
        #expect(screen.contentState.screen == .loading)

        NodeActionsTextFileEditPresenter.editAfterOpen(in: nav)
        try await Self.waitUntil { screen.contentState.screen == .editor }

        let names = tracker.trackedEventIdentifiers.map { String(describing: type(of: $0)) }
        #expect(names.contains("MEGAAOSEditTextFileActionEvent"))
        #expect(screen.contentState.screen == .editor)
        #expect(screen.contentState.textEditorMode == .richText)
    }

    @Test func overLimitMarkdownWithGateOnUsesTheVisibleScreen() {
        let screen = Self.makeScreen()
        let nav = UINavigationController(rootViewController: screen)
        let node = NodeEntity(name: "big.md", handle: 1, isFile: true, size: Self.overLimit)

        let presenter = NodeActionsTextFileEditPresenter.presenter(for: node, in: nav, isMarkdownEditorEnabled: true)

        #expect(presenter === screen)
    }

    @Test func markdownWithGateOffKeepsTheNavigationController() {
        let nav = UINavigationController(rootViewController: Self.makeScreen())
        let node = NodeEntity(name: "notes.md", handle: 1, isFile: true, size: 10)

        let presenter = NodeActionsTextFileEditPresenter.presenter(for: node, in: nav, isMarkdownEditorEnabled: false)

        #expect(presenter === nav)
    }

    @Test func plainTextWithGateOnKeepsTheNavigationController() {
        let nav = UINavigationController(rootViewController: Self.makeScreen())
        let node = NodeEntity(name: "notes.txt", handle: 1, isFile: true, size: 10)

        let presenter = NodeActionsTextFileEditPresenter.presenter(for: node, in: nav, isMarkdownEditorEnabled: true)

        #expect(presenter === nav)
    }

    @Test func markdownWithGateOnFallsBackToNavigationControllerWhenEmpty() {
        let nav = UINavigationController()
        let node = NodeEntity(name: "notes.md", handle: 1, isFile: true, size: 10)

        let presenter = NodeActionsTextFileEditPresenter.presenter(for: node, in: nav, isMarkdownEditorEnabled: true)

        #expect(presenter === nav)
    }

    @Test func editAfterOpenOnOtherScreenDoesNothing() {
        let nav = UINavigationController(rootViewController: UIViewController())

        NodeActionsTextFileEditPresenter.editAfterOpen(in: nav)

        #expect(nav.viewControllers.count == 1)
    }

    @Test func editAfterOpenOnDocumentPreviewShowsUnknownEncodingHud() {
        let preview = PreviewDocumentViewController()
        let nav = UINavigationController(rootViewController: preview)

        NodeActionsTextFileEditPresenter.editAfterOpen(in: nav)

        #expect(preview.showUnknownEncodeHud)
    }
}
