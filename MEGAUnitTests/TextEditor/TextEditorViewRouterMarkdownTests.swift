import Foundation
@testable import MEGA
import MEGADomain
import MEGAL10n
import Testing
import UIKit

@MainActor
struct TextEditorViewRouterMarkdownTests {
    private static let limit: UInt64 = 100 * 1024 * 1024

    private static func makeRouter(
        fileName: String,
        mode: TextEditorMode,
        nodeSize: UInt64 = 10,
        isMarkdownEditorEnabled: Bool = true,
        textFile: TextFile? = nil
    ) -> TextEditorViewRouter {
        let node = NodeEntity(name: fileName, handle: 77, isFile: true, size: nodeSize)
        return TextEditorViewRouter(
            textFile: textFile ?? TextFile(fileName: fileName),
            textEditorMode: mode,
            nodeEntity: node,
            presenter: UIViewController(),
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        )
    }

    private static func makeCreateRouter(fileName: String, isMarkdownEditorEnabled: Bool = true) -> TextEditorViewRouter {
        TextEditorViewRouter(
            textFile: TextFile(fileName: fileName),
            textEditorMode: .create,
            parentHandle: 5,
            presenter: UIViewController(),
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        )
    }

    /// Opens a cached file the way the Objective-C node flow does, with a node of the given size.
    private static func openCachedFile(
        atPath path: String,
        fileName: String,
        nodeSize: UInt64 = 10,
        isMarkdownEditorEnabled: Bool = true
    ) -> UIViewController? {
        TextEditorOpener.makeCachedTextViewController(
            filePath: path,
            fileName: fileName,
            sizeInBytes: nodeSize,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        ) { content, encoding in
            let textFile = TextFile(fileName: fileName, content: content, size: nodeSize, encode: encoding.rawValue)
            return makeRouter(fileName: fileName, mode: .view, nodeSize: nodeSize, isMarkdownEditorEnabled: isMarkdownEditorEnabled, textFile: textFile)
        }
    }

    private static func firstScreen(of controller: UIViewController?) -> UIViewController? {
        (controller as? UINavigationController)?.viewControllers.first
    }

    private static func makeTempFile(named name: String, data: Data) throws -> (path: String, cleanup: () -> Void) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(name)
        try data.write(to: url)
        return (url.path, { try? FileManager.default.removeItem(at: folder) })
    }

    // MARK: - build

    @Test func buildLoadModeForMarkdownReturnsMarkdownScreenInNavigationController() throws {
        let sut = Self.makeRouter(fileName: "a.md", mode: .load)
        let nav = try #require(sut.build() as? MEGANavigationController)
        #expect(nav.viewControllers.first is MarkdownTextEditorViewController)
    }

    @Test func buildLoadModeForOverLimitMarkdownReturnsTooLargeAlert() {
        let sut = Self.makeRouter(fileName: "a.md", mode: .load, nodeSize: Self.limit + 1)
        #expect(sut.build() is UIAlertController)
    }

    @Test func buildLoadModeUsesNodeSize() {
        // The text file passed to the router has no size. Only the node knows it.
        let atLimit = Self.makeRouter(fileName: "a.md", mode: .load, nodeSize: Self.limit)
        let overLimit = Self.makeRouter(fileName: "a.md", mode: .load, nodeSize: Self.limit + 1)
        #expect(Self.firstScreen(of: atLimit.build()) is MarkdownTextEditorViewController)
        #expect(overLimit.build() is UIAlertController)
    }

    @Test func buildCreateModeForMarkdownReturnsMarkdownScreen() {
        let sut = Self.makeCreateRouter(fileName: "notes.md")
        #expect(Self.firstScreen(of: sut.build()) is MarkdownTextEditorViewController)
    }

    @Test func buildCreateModeForTextKeepsLegacyScreen() {
        let sut = Self.makeCreateRouter(fileName: "notes.txt")
        #expect(Self.firstScreen(of: sut.build()) is TextEditorViewController)
    }

    @Test func buildWithGateOffKeepsLegacyScreen() {
        let loadRouter = Self.makeRouter(fileName: "a.md", mode: .load, isMarkdownEditorEnabled: false)
        let createRouter = Self.makeCreateRouter(fileName: "notes.md", isMarkdownEditorEnabled: false)
        #expect(Self.firstScreen(of: loadRouter.build()) is TextEditorViewController)
        #expect(Self.firstScreen(of: createRouter.build()) is TextEditorViewController)
    }

    @Test func buildViewModeWithoutCachedCheckKeepsLegacyScreen() {
        // A view mode build that did not come from the cached open has not checked the file bytes.
        let sut = Self.makeRouter(fileName: "a.md", mode: .view)
        #expect(Self.firstScreen(of: sut.build()) is TextEditorViewController)
    }

    // MARK: - Cached open

    @Test func cachedUTF8MarkdownOpensMarkdownScreen() throws {
        let file = try Self.makeTempFile(named: "a.md", data: Data("# Title".utf8))
        defer { file.cleanup() }
        #expect(Self.firstScreen(of: Self.openCachedFile(atPath: file.path, fileName: "a.md")) is MarkdownTextEditorViewController)
    }

    @Test func cachedInvalidUTF8MarkdownReturnsNil() throws {
        // UTF-16 with a byte order mark: the legacy reader decodes it, but Markdown needs UTF-8.
        // Nil lets the caller open the document preview, like a downloaded file.
        let utf16 = try #require("# Title".data(using: .utf16))
        let file = try Self.makeTempFile(named: "a.md", data: utf16)
        defer { file.cleanup() }
        #expect(Self.openCachedFile(atPath: file.path, fileName: "a.md") == nil)
    }

    @Test func cachedUTF8MarkdownScreenIsAPreviewWithTheFileText() async throws {
        let file = try Self.makeTempFile(named: "a.md", data: Data("# Title".utf8))
        defer { file.cleanup() }
        let screen = try #require(Self.firstScreen(of: Self.openCachedFile(atPath: file.path, fileName: "a.md")) as? MarkdownTextEditorViewController)

        screen.loadViewIfNeeded()
        for _ in 0..<500 where screen.contentState.screen != .preview {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(screen.contentState.screen == .preview)
        #expect(screen.contentState.text == "# Title")
    }

    @Test func cachedUndecodableFileReturnsNil() throws {
        // No text encoding decodes these bytes, so the caller can try other viewers.
        let file = try Self.makeTempFile(named: "a.txt", data: Data([0x80, 0x81, 0x82, 0x83]))
        defer { file.cleanup() }
        #expect(Self.openCachedFile(atPath: file.path, fileName: "a.txt") == nil)
    }

    @Test func cachedUndecodableMarkdownReturnsNil() throws {
        let file = try Self.makeTempFile(named: "a.md", data: Data([0x80, 0x81, 0x82, 0x83]))
        defer { file.cleanup() }
        #expect(Self.openCachedFile(atPath: file.path, fileName: "a.md") == nil)
    }

    @Test func cachedOverLimitMarkdownReturnsAlertWithoutReading() {
        // The file does not exist. An alert means the size check ran before any read.
        #expect(Self.openCachedFile(atPath: "/nonexistent/a.md", fileName: "a.md", nodeSize: Self.limit + 1) is UIAlertController)
    }

    @Test func cachedMarkdownWithGateOffOpensLegacyTextEditor() throws {
        let file = try Self.makeTempFile(named: "a.md", data: Data("# Title".utf8))
        defer { file.cleanup() }
        #expect(Self.firstScreen(of: Self.openCachedFile(atPath: file.path, fileName: "a.md", isMarkdownEditorEnabled: false)) is TextEditorViewController)
    }

    @Test func cachedPlainTextOpensLegacyTextEditor() throws {
        let file = try Self.makeTempFile(named: "a.txt", data: Data("hello".utf8))
        defer { file.cleanup() }
        #expect(Self.firstScreen(of: Self.openCachedFile(atPath: file.path, fileName: "a.txt")) is TextEditorViewController)
    }

    @Test func cachedMissingFileReturnsNil() {
        #expect(Self.openCachedFile(atPath: "/nonexistent/a.txt", fileName: "a.txt") == nil)
    }

    // MARK: - Link files

    @Test func linkMarkdownUnderTheLimitOpensInTextEditor() {
        #expect(TextEditorOpener.opensLinkFileInTextEditor(fileName: "a.md", sizeInBytes: Self.limit, isMarkdownEditorEnabled: true))
    }

    @Test func linkPlainTextKeepsDocumentPreview() {
        #expect(!TextEditorOpener.opensLinkFileInTextEditor(fileName: "a.txt", sizeInBytes: 10, isMarkdownEditorEnabled: true))
    }

    @Test func linkMarkdownOverTheLimitKeepsDocumentPreview() {
        #expect(!TextEditorOpener.opensLinkFileInTextEditor(fileName: "a.md", sizeInBytes: Self.limit + 1, isMarkdownEditorEnabled: true))
    }

    @Test func linkMarkdownWithGateOffKeepsDocumentPreview() {
        #expect(!TextEditorOpener.opensLinkFileInTextEditor(fileName: "a.md", sizeInBytes: 10, isMarkdownEditorEnabled: false))
    }

    // MARK: - Too large alert

    @Test func tooLargeAlertOffersDownloadAndCancel() throws {
        // The router keeps its presenter weakly, so the test holds it.
        let presenter = UIViewController()
        let node = NodeEntity(name: "a.md", handle: 77, isFile: true, size: Self.limit + 1)
        let sut = TextEditorViewRouter(
            textFile: TextFile(fileName: "a.md"),
            textEditorMode: .load,
            nodeEntity: node,
            presenter: presenter,
            isMarkdownEditorEnabled: true
        )

        let alert = try #require(sut.build() as? UIAlertController)

        let size = String.memoryStyleString(fromByteCount: Int64(Self.limit + 1))
        #expect(alert.title == Strings.Localizable.MarkdownEditor.FileTooLarge.title)
        #expect(alert.message == Strings.Localizable.MarkdownEditor.FileTooLarge.message(size))
        #expect(alert.actions.map(\.title) == [Strings.Localizable.cancel, Strings.Localizable.download])
        #expect(alert.actions.map(\.style) == [.cancel, .default])
    }

    @Test func tooLargeAlertWithoutANodeShowsOnlyCancel() {
        let alert = TextEditorViewRouter.makeMarkdownTooLargeAlert(node: nil, presenter: UIViewController())

        #expect(alert.actions.map(\.title) == [Strings.Localizable.cancel])
    }

    // MARK: - Dismiss

    /// Shows the editor of `router` in a window, presented the way `start()` presents it.
    private static func presentEditor(of router: TextEditorViewRouter) -> (window: UIWindow, presenter: UIViewController, editor: UIViewController) {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        let editor = router.build()
        presenter.present(editor, animated: false)
        return (window, presenter, editor)
    }

    /// Dismissal is animated, so the test waits until the condition holds.
    private static func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for _ in 0..<300 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        if !condition() { Issue.record("The condition did not hold within 3 seconds", sourceLocation: sourceLocation) }
    }

    @Test(arguments: ["notes.md", "notes.txt"])
    func closingTheEditorAlsoClosesTheScreenOnTopOfIt(fileName: String) async throws {
        let sut = Self.makeCreateRouter(fileName: fileName)
        let (window, presenter, editor) = Self.presentEditor(of: sut)
        defer { window.isHidden = true }
        // Stands for the folder picker, which the editor presents.
        editor.present(UIViewController(), animated: false)

        sut.dismissTextEditorVC()

        try await Self.waitUntil { presenter.presentedViewController == nil }
    }

    @Test func closingThePickerWhenNoPickerIsShownKeepsTheEditor() async throws {
        let sut = Self.makeCreateRouter(fileName: "notes.md")
        let (window, presenter, editor) = Self.presentEditor(of: sut)
        defer { window.isHidden = true }

        sut.dismissBrowserVC()
        try await Task.sleep(for: .milliseconds(500))

        #expect(presenter.presentedViewController === editor)
    }
}
