import Foundation
@testable import MEGA
import MEGAAppSDKRepoMock
import MEGAAssets
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

    // MARK: - Markdown from Offline, Chat, Transfers and Versions

    private final class ReadCounter {
        var count = 0
    }

    private static func openOfflineFile(
        named fileName: String = "notes.md",
        sizeInBytes: UInt64 = 10,
        isMarkdownEditorEnabled: Bool = true,
        data: Data? = Data("# Title".utf8),
        counter: ReadCounter = ReadCounter()
    ) -> UIViewController? {
        TextEditorOpener.makeOfflineMarkdownViewController(
            filePath: "/offline/\(fileName)",
            sizeInBytes: sizeInBytes,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        ) { _ in
            counter.count += 1
            return data
        }
    }

    @Test func opensFileOnMarkdownScreen_markdownUnderLimit_returnsTrue() {
        #expect(TextEditorOpener.opensFileOnMarkdownScreen(fileName: "a.md", sizeInBytes: Self.limit, isMarkdownEditorEnabled: true))
    }

    @Test func opensFileOnMarkdownScreen_plainText_returnsFalse() {
        #expect(!TextEditorOpener.opensFileOnMarkdownScreen(fileName: "a.txt", sizeInBytes: 10, isMarkdownEditorEnabled: true))
    }

    @Test func opensFileOnMarkdownScreen_markdownOverLimit_returnsFalse() {
        #expect(!TextEditorOpener.opensFileOnMarkdownScreen(fileName: "a.md", sizeInBytes: Self.limit + 1, isMarkdownEditorEnabled: true))
    }

    @Test func opensFileOnMarkdownScreen_gateOff_returnsFalse() {
        #expect(!TextEditorOpener.opensFileOnMarkdownScreen(fileName: "a.md", sizeInBytes: 10, isMarkdownEditorEnabled: false))
    }

    @Test func offlineMarkdown_underLimit_opensMarkdownScreen() {
        #expect(Self.firstScreen(of: Self.openOfflineFile()) is MarkdownTextEditorViewController)
    }

    @Test func offlineMarkdown_gateOff_returnsNil() {
        #expect(Self.openOfflineFile(isMarkdownEditorEnabled: false) == nil)
    }

    @Test func offlinePlainText_underLimit_returnsNil() {
        #expect(Self.openOfflineFile(named: "notes.txt") == nil)
    }

    @Test func offlineMarkdown_overLimit_doesNotReadFile() {
        let counter = ReadCounter()
        let screen = Self.openOfflineFile(sizeInBytes: Self.limit + 1, counter: counter)
        #expect(screen == nil)
        #expect(counter.count == 0)
    }

    @Test func offlineMarkdown_underLimit_readsFileOnce() {
        let counter = ReadCounter()
        _ = Self.openOfflineFile(counter: counter)
        #expect(counter.count == 1)
    }

    @Test func offlineMarkdown_invalidUTF8_returnsNil() throws {
        // UTF-16 with a byte order mark is not valid UTF-8. The caller opens the document preview.
        let utf16 = try #require("# Title".data(using: .utf16))
        #expect(Self.openOfflineFile(data: utf16) == nil)
    }

    @Test func offlineMarkdownScreen_afterSetUp_hasNoMoreAndNoBottomBar() async throws {
        let screen = try #require(Self.firstScreen(of: Self.openOfflineFile()) as? MarkdownTextEditorViewController)
        screen.loadViewIfNeeded()
        for _ in 0..<500 where screen.navigationItem.leftBarButtonItem == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(screen.navigationItem.leftBarButtonItem != nil)

        #expect(screen.toolbarItems?.isEmpty ?? true)
        #expect((screen.navigationItem.rightBarButtonItems ?? []).contains { $0.image == MEGAAssets.UIImage.moreNavigationBar } == false)
    }

    @Test func nodeActionsDisplayMode_cloudDrive_isTextEditor() {
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: .cloudDrive, isInRubbishBin: false) == .textEditor)
    }

    @Test(arguments: [TextEditorFileSource.offline, .chat, .transfers, .versions])
    func nodeActionsDisplayMode_nodeSources_isPreviewDocument(source: TextEditorFileSource) {
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: source, isInRubbishBin: false) == .previewDocument)
    }

    @Test func nodeOpenerSource_transfersDisplayMode_isTransfers() {
        #expect(NodeOpener.textEditorSource(for: .transfers) == .transfers)
    }

    @Test(arguments: [DisplayMode?.none, .cloudDrive, .sharedItem, .recents])
    func nodeOpenerSource_otherDisplayMode_isCloudDrive(displayMode: DisplayMode?) {
        #expect(NodeOpener.textEditorSource(for: displayMode) == .cloudDrive)
    }

    @Test(arguments: [TextEditorFileSource.cloudDrive, .chat, .transfers, .versions])
    func nodeActionsDisplayMode_inRubbishBin_isRubbishBin(source: TextEditorFileSource) {
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: source, isInRubbishBin: true) == .rubbishBin)
    }

    @Test func downloadTransfer_chatIds_isChatDownload() {
        let node = NodeEntity(name: "a.md", handle: 77, isFile: true, size: 10)

        let transfer = TextEditorViewRouter.makeDownloadTransfer(node: node, chatId: 5, messageId: 6)

        #expect(transfer.type == .downloadChat)
        #expect(transfer.handle == 77)
        #expect(transfer.chatId == 5)
        #expect(transfer.messageId == 6)
    }

    @Test func downloadTransfer_noChatIds_isNodeDownload() {
        let node = NodeEntity(name: "a.md", handle: 77, isFile: true, size: 10)

        let transfer = TextEditorViewRouter.makeDownloadTransfer(node: node, chatId: nil, messageId: nil)

        #expect(transfer.type == .download)
        #expect(transfer.handle == 77)
    }

    @Test(arguments: [TextEditorFileSource.cloudDrive, .offline, .chat, .transfers])
    func isInVersionsView_otherSources_isFalse(source: TextEditorFileSource) {
        #expect(!TextEditorViewRouter.isInVersionsView(for: source))
    }

    @Test func isInVersionsView_versionsSource_isTrue() {
        #expect(TextEditorViewRouter.isInVersionsView(for: .versions))
    }

    @Test(arguments: [TextEditorFileSource.offline, .chat, .transfers, .versions])
    func actionsNode_nodeSourceWithoutAccountNode_usesOpenedNode(source: TextEditorFileSource) {
        #expect(TextEditorViewRouter.actionsNode(accountNode: String?.none, openedNode: "opened", source: source) == "opened")
    }

    @Test func actionsNode_cloudDriveWithoutAccountNode_isNil() {
        #expect(TextEditorViewRouter.actionsNode(accountNode: String?.none, openedNode: "opened", source: .cloudDrive) == nil)
    }

    @Test(arguments: [TextEditorFileSource.cloudDrive, .chat, .versions])
    func actionsNode_withAccountNode_usesAccountNode(source: TextEditorFileSource) {
        #expect(TextEditorViewRouter.actionsNode(accountNode: "account", openedNode: "opened", source: source) == "account")
    }

    @Test func previewFields_chatSource_setChatIds() {
        let router = TextEditorViewRouter(
            textFile: TextFile(fileName: "a.md"),
            textEditorMode: .view,
            presenter: UIViewController(),
            isMarkdownEditorEnabled: true,
            source: .chat,
            chatId: 5,
            messageId: 6
        )
        let previewVC = PreviewDocumentViewController()

        router.configureSourceFields(of: previewVC)

        #expect(previewVC.chatId == 5)
        #expect(previewVC.messageId == 6)
        #expect(!previewVC.isLink)
    }

    @Test func previewFields_transfersSource_setNodeHandleOnly() {
        let router = Self.makeRouter(fileName: "a.md", mode: .view)
        let previewVC = PreviewDocumentViewController()

        router.configureSourceFields(of: previewVC)

        #expect(previewVC.nodeHandle == 77)
        #expect(previewVC.chatId == 0)
    }

    // MARK: - Files that keep the document preview or the earlier behaviour

    @Test(arguments: [("notes.txt", UInt64(10)), ("notes.md", UInt64(104_857_601))])
    func fourScreens_plainTextOrLargeMarkdown_keepDocumentPreview(fileName: String, sizeInBytes: UInt64) {
        #expect(!TextEditorOpener.opensFileOnMarkdownScreen(fileName: fileName, sizeInBytes: sizeInBytes, isMarkdownEditorEnabled: true))
        #expect(Self.openOfflineFile(named: fileName, sizeInBytes: sizeInBytes) == nil)
    }

    @Test func fourScreens_flagOff_keepDocumentPreview() {
        #expect(!TextEditorOpener.opensFileOnMarkdownScreen(fileName: "notes.md", sizeInBytes: 10, isMarkdownEditorEnabled: false))
        #expect(Self.openOfflineFile(isMarkdownEditorEnabled: false) == nil)
    }

    @Test func cloudDriveHomeLinks_markdownFile_openAsBefore() throws {
        let file = try Self.makeTempFile(named: "notes.md", data: Data("# Title".utf8))
        defer { file.cleanup() }

        let cached = Self.openCachedFile(atPath: file.path, fileName: "notes.md")

        #expect(Self.firstScreen(of: cached) is MarkdownTextEditorViewController)
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: .cloudDrive, isInRubbishBin: false) == .textEditor)
        #expect(TextEditorOpener.opensLinkFileInTextEditor(fileName: "notes.md", sizeInBytes: 10, isMarkdownEditorEnabled: true))
    }

    @Test func chatMarkdown_ownAttachment_opensWithoutEdit() {
        // The preview actions have no Edit. A chat file never uses the text editor actions.
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: .chat, isInRubbishBin: false) == .previewDocument)
        #expect(TextEditorViewRouter.nodeActionsDisplayMode(for: .chat, isInRubbishBin: false) != .textEditor)
    }

    // MARK: - Source through the node opener

    /// Opens a cached Markdown file of a node the way the Objective-C node flow does, and waits for setUp.
    private static func openCachedNodeFileAndWaitForSetUp(source: TextEditorFileSource) async throws -> MarkdownTextEditorViewController {
        let file = try makeTempFile(named: "notes.md", data: Data("# Title".utf8))
        defer { file.cleanup() }
        let controller = TextEditorOpener.makeCachedTextViewController(
            node: MockNode(handle: 77, name: "notes.md"),
            filePath: file.path,
            isFromSharedItem: false,
            isLink: false,
            fileLink: nil,
            presenter: UIViewController(),
            source: source,
            chatId: 5,
            messageId: 6,
            isMarkdownEditorEnabled: true
        )
        let screen = try #require(firstScreen(of: controller) as? MarkdownTextEditorViewController)
        screen.loadViewIfNeeded()
        for _ in 0..<500 where screen.navigationItem.leftBarButtonItem == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(screen.navigationItem.leftBarButtonItem != nil)
        return screen
    }

    @Test(arguments: [TextEditorFileSource.chat, .transfers, .versions])
    func cachedNodeFile_nodeSource_opensWithMoreAndNoBottomBar(source: TextEditorFileSource) async throws {
        let screen = try await Self.openCachedNodeFileAndWaitForSetUp(source: source)

        #expect(screen.toolbarItems?.isEmpty ?? true)
        #expect((screen.navigationItem.rightBarButtonItems ?? []).contains { $0.image == MEGAAssets.UIImage.moreNavigationBar })
    }

    @Test func cachedNodeFile_cloudDriveSource_opensWithBottomBar() async throws {
        // Cloud drive keeps the bar on the same path. So a lost source changes the bar.
        let screen = try await Self.openCachedNodeFileAndWaitForSetUp(source: .cloudDrive)

        #expect(screen.toolbarItems?.isEmpty == false)
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
