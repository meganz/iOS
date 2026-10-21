@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATextEditor
import MEGAUIKit
import SwiftUI
import Testing
import UIKit

/// Serialized because some tests make their window key and then wait. A parallel test could take the key window.
@Suite(.serialized)
@MainActor
struct MarkdownTextEditorViewControllerTests {
    private struct Fixture {
        let sut: MarkdownTextEditorViewController
        let router: MockTextEditorViewRouter
        let tracker: MockTracker
        let upload: MockUploadFileUseCase
        let viewModel: TextEditorViewModel
    }

    private static func makeFixture(
        mode: TextEditorMode = .view,
        accessLevel: NodeAccessTypeEntity = .owner,
        fileName: String = "notes.md",
        content: String = "",
        parentHandle: HandleEntity? = nil,
        nodeEntity: NodeEntity? = NodeEntity(name: "notes.md", handle: 77, isFile: true, size: 10),
        isLink: Bool = false,
        source: TextEditorFileSource = .cloudDrive
    ) -> Fixture {
        let router = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let upload = MockUploadFileUseCase(duplicate: false, uploadFileResult: .success(()), filename: fileName)
        let viewModel = TextEditorViewModel(
            router: router,
            textFile: TextFile(fileName: fileName, content: content, size: 0, encode: String.Encoding.utf8.rawValue),
            textEditorMode: mode,
            uploadFileUseCase: upload,
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: accessLevel),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            parentHandle: parentHandle,
            nodeEntity: nodeEntity,
            isLink: isLink,
            source: source,
            tracker: tracker
        )
        let sut = MarkdownTextEditorViewController(viewModel: viewModel)
        sut.loadViewIfNeeded()
        return Fixture(sut: sut, router: router, tracker: tracker, upload: upload, viewModel: viewModel)
    }

    private static func configure(
        _ sut: MarkdownTextEditorViewController,
        mode: TextEditorMode,
        accessLevel: NodeAccessTypeEntity? = .owner,
        fileName: String = "notes.md",
        content: String = "",
        isInRubbishBin: Bool = false,
        isBackupNode: Bool = false
    ) {
        let model = TextEditorModel(
            textFile: TextFile(fileName: fileName, content: content, size: 0, encode: String.Encoding.utf8.rawValue),
            textEditorMode: mode,
            accessLevel: accessLevel,
            resumeReadingOffset: nil
        )
        sut.executeCommand(.configView(model, shallUpdateContent: true, isInRubbishBin: isInRubbishBin, isBackupNode: isBackupNode))
        let isEditing = mode == .edit || mode == .create
        let navbar = TextEditorNavbarItemsModel(
            leftItem: NavbarItemModel(title: isEditing ? Strings.Localizable.cancel : Strings.Localizable.close, image: nil),
            rightItem: isEditing ? NavbarItemModel(title: Strings.Localizable.save, image: nil) : NavbarItemModel(title: nil, image: nil),
            textEditorMode: mode
        )
        sut.executeCommand(.setupNavbarItems(navbar))
    }

    private static func fire(_ item: UIBarButtonItem) {
        guard let action = item.action else { return }
        _ = (item.target as? NSObject)?.perform(action, with: item)
    }

    /// The view model sends commands on the main queue. The test waits until the condition holds.
    /// A timeout is recorded at the caller, so the failure names the wait, not a later expectation.
    private static func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for _ in 0..<500 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        if !condition() { Issue.record("The condition did not hold within 5 seconds", sourceLocation: sourceLocation) }
    }

    /// Waits for the commands from the first `setUpView`, so they do not overwrite what a test sets.
    /// `setupNavbarItems` is the last of those commands, and it always sets the left item.
    private static func waitForSetUp(_ sut: MarkdownTextEditorViewController) async throws {
        try await waitUntil { sut.navigationItem.leftBarButtonItem != nil }
        try #require(sut.navigationItem.leftBarButtonItem != nil)
    }

    /// SwiftUI starts the `task` and `onAppear` work of the editor only in a window of a scene.
    private static func makeSceneWindow(rootViewController: UIViewController) -> UIWindow {
        let window = if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            UIWindow(windowScene: scene)
        } else {
            UIWindow()
        }
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        return window
    }

    private static func sourceTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView, textView.accessibilityIdentifier == "editor.source" {
            return textView
        }
        return view.subviews.lazy.compactMap { sourceTextView(in: $0) }.first
    }

    private static func modeItem(of sut: MarkdownTextEditorViewController) -> UIBarButtonItem? {
        sut.navigationItem.rightBarButtonItems?.first { $0.menu != nil }
    }

    // MARK: - Content

    @Test func hostingControllerIsChildOfScreen() {
        let fixture = Self.makeFixture()
        #expect(fixture.sut.children.contains { $0 is UIHostingController<MarkdownTextEditorContentView> })
    }

    // MARK: - View and load modes

    @Test func viewModeCommandShowsPreviewWithFileText() {
        let fixture = Self.makeFixture()

        Self.configure(fixture.sut, mode: .view, content: "# Title")

        #expect(fixture.sut.contentState.screen == .preview)
        #expect(fixture.sut.contentState.text == "# Title")
    }

    @Test func loadModeShowsLoadingThenPreviewAfterDownload() {
        let fixture = Self.makeFixture()

        fixture.sut.executeCommand(.setupLoadViews)
        #expect(fixture.sut.contentState.screen == .loading)
        #expect(fixture.sut.contentState.loadingProgress == nil)

        Self.configure(fixture.sut, mode: .view, content: "Downloaded")
        #expect(fixture.sut.contentState.screen == .preview)
        #expect(fixture.sut.contentState.text == "Downloaded")
    }

    @Test func loadModeNavItemsAreCloseOnly() {
        let fixture = Self.makeFixture(mode: .load)

        Self.configure(fixture.sut, mode: .load, accessLevel: nil)

        #expect(fixture.sut.contentState.screen != .preview)
        #expect(fixture.sut.navigationItem.leftBarButtonItem?.title == Strings.Localizable.close)
        #expect(fixture.sut.navigationItem.rightBarButtonItems == nil)
        #expect(fixture.sut.toolbarItems == nil)
    }

    @Test func progressCommandUpdatesLoadingProgress() {
        let fixture = Self.makeFixture()

        fixture.sut.executeCommand(.updateProgressView(progress: 0.5))

        #expect(fixture.sut.contentState.screen == .loading)
        #expect(fixture.sut.contentState.loadingProgress == 0.5)
    }

    @Test func viewModeNavItemsAreCloseAndMore() {
        let fixture = Self.makeFixture()

        Self.configure(fixture.sut, mode: .view)

        #expect(fixture.sut.navigationItem.leftBarButtonItem?.title == Strings.Localizable.close)
        let right = fixture.sut.navigationItem.rightBarButtonItems
        #expect(right?.count == 1)
        #expect(right?.first?.image == MEGAAssets.UIImage.moreNavigationBar)
    }

    @Test func loadModeGivesTheFileNameToTheLoadingIcon() {
        let fixture = Self.makeFixture()

        fixture.sut.executeCommand(.setupLoadViews)
        Self.configure(fixture.sut, mode: .load, fileName: "readme.md")

        #expect(fixture.sut.contentState.screen == .loading)
        #expect(fixture.sut.contentState.fileName == "readme.md")
    }

    @Test func titleShowsFileName() {
        let fixture = Self.makeFixture()

        Self.configure(fixture.sut, mode: .view, fileName: "readme.md")

        if #available(iOS 26.0, *) {
            #expect(fixture.sut.navigationItem.titleView != nil)
        } else {
            #expect(fixture.sut.navigationItem.title == "readme.md")
        }
    }

    // MARK: - Bottom bar

    @Test func viewModeSetsBottomBarByAccess() {
        let owner = Self.makeFixture(accessLevel: .owner)
        Self.configure(owner.sut, mode: .view, accessLevel: .owner)
        // Download, space, Edit, space, Export.
        #expect(owner.sut.toolbarItems?.count == 5)

        let reader = Self.makeFixture(accessLevel: .read)
        Self.configure(reader.sut, mode: .view, accessLevel: .read)
        // Download, space, Import. A reader cannot edit.
        #expect(reader.sut.toolbarItems?.count == 3)
    }

    @Test(arguments: [NodeAccessTypeEntity.owner, .read])
    func rubbishBinHidesToolbar(accessLevel: NodeAccessTypeEntity) {
        let fixture = Self.makeFixture(accessLevel: accessLevel)

        Self.configure(fixture.sut, mode: .view, accessLevel: accessLevel, isInRubbishBin: true)

        #expect(fixture.sut.toolbarItems == nil)
    }

    @Test func backupNodeShowsReadOnlyBottomBar() {
        let fixture = Self.makeFixture(accessLevel: .owner)

        Self.configure(fixture.sut, mode: .view, accessLevel: .owner, isBackupNode: true)

        // Download, space, Import. A backup node cannot be edited.
        #expect(fixture.sut.toolbarItems?.count == 3)
    }

    @Test func editModeHidesToolbar() {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .view, accessLevel: .owner)
        #expect(fixture.sut.toolbarItems != nil)

        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        #expect(fixture.sut.toolbarItems == nil)
    }

    @Test func linkFileShowsDownloadAndImportWithoutMore() async throws {
        // The account owns no link file, even when the SDK reports another access level.
        let fixture = Self.makeFixture(accessLevel: .owner, isLink: true)

        fixture.viewModel.dispatch(.setUpView)
        try await Self.waitForSetUp(fixture.sut)

        let actions = fixture.sut.toolbarItems?.compactMap(\.action)
        #expect(actions == [#selector((any TextEditorBarItemTarget).downloadTapped), #selector((any TextEditorBarItemTarget).importTapped)])
        let right = fixture.sut.navigationItem.rightBarButtonItems ?? []
        #expect(right.contains { $0.image == MEGAAssets.UIImage.moreNavigationBar } == false)
    }

    @Test(arguments: [TextEditorFileSource.chat, .transfers, .versions])
    func nodeSourceFile_setUpView_showsMoreWithoutBottomBar(source: TextEditorFileSource) async throws {
        let fixture = Self.makeFixture(accessLevel: .owner, source: source)

        fixture.viewModel.dispatch(.setUpView)
        try await Self.waitForSetUp(fixture.sut)

        #expect(fixture.sut.toolbarItems?.isEmpty ?? true)
        let right = fixture.sut.navigationItem.rightBarButtonItems ?? []
        #expect(right.contains { $0.image == MEGAAssets.UIImage.moreNavigationBar })
    }

    @Test func offlineFile_setUpView_showsNoMoreAndNoBottomBar() async throws {
        let fixture = Self.makeFixture(accessLevel: .owner, source: .offline)

        fixture.viewModel.dispatch(.setUpView)
        try await Self.waitForSetUp(fixture.sut)

        #expect(fixture.sut.toolbarItems?.isEmpty ?? true)
        let right = fixture.sut.navigationItem.rightBarButtonItems ?? []
        #expect(right.contains { $0.image == MEGAAssets.UIImage.moreNavigationBar } == false)
    }

    @Test func cloudDriveFile_setUpView_showsBottomBarAndMore() async throws {
        let fixture = Self.makeFixture(accessLevel: .owner)

        fixture.viewModel.dispatch(.setUpView)
        try await Self.waitForSetUp(fixture.sut)

        #expect(fixture.sut.toolbarItems?.isEmpty == false)
        let right = fixture.sut.navigationItem.rightBarButtonItems ?? []
        #expect(right.contains { $0.image == MEGAAssets.UIImage.moreNavigationBar })
    }

    @Test func configView_viewModeWithoutAccessLevel_hidesBottomBar() {
        let fixture = Self.makeFixture()

        Self.configure(fixture.sut, mode: .view, accessLevel: nil)

        #expect(fixture.sut.toolbarItems?.isEmpty ?? true)
    }

    @Test func moreTapPassesBarButtonItemAsSender() throws {
        let fixture = Self.makeFixture()
        Self.configure(fixture.sut, mode: .view)
        let moreItem = try #require(fixture.sut.navigationItem.rightBarButtonItems?.first)

        Self.fire(moreItem)

        #expect(fixture.router.showActions_calledTimes == 1)
        #expect(fixture.router.showActions_sender as? UIBarButtonItem === moreItem)
    }

    @Test func closeTapDismissesThroughRouter() throws {
        let fixture = Self.makeFixture()
        Self.configure(fixture.sut, mode: .view)
        let closeItem = try #require(fixture.sut.navigationItem.leftBarButtonItem)

        Self.fire(closeItem)

        #expect(fixture.router.dismissTextEditorVC_calledTimes == 1)
    }

    /// Replace uploads the new file. The editor closes once, after the upload, and no Close tap is tracked.
    @Test func replaceInDuplicateNameAlertUploadsWithoutCloseEvent() throws {
        let fixture = Self.makeFixture(mode: .create, parentHandle: 5, nodeEntity: nil)
        let window = Self.makeSceneWindow(rootViewController: fixture.sut)
        defer { window.isHidden = true }
        fixture.sut.executeCommand(.showDuplicateNameAlert(TextEditorDuplicateNameAlertModel(
            alertTitle: "Name taken",
            alertMessage: "A file with this name exists",
            cancelButtonTitle: Strings.Localizable.cancel,
            replaceButtonTitle: Strings.Localizable.replace,
            renameButtonTitle: Strings.Localizable.rename
        )))
        let alert = try #require(fixture.sut.presentedViewController as? UIAlertController)
        let replace = try #require(alert.actions.first { $0.title == Strings.Localizable.replace })

        // Test-only way to run the handler of an alert action.
        typealias AlertActionHandler = @convention(block) (UIAlertAction) -> Void
        unsafeBitCast(replace.value(forKey: "handler") as AnyObject, to: AlertActionHandler.self)(replace)

        #expect(fixture.router.dismissBrowserVC_calledTimes == 1)
        #expect(fixture.router.dismissTextEditorVC_calledTimes == 1)
        let closeEventName = String(describing: type(of: TextEditorCloseMenuToolbarEvent()))
        let names = fixture.tracker.trackedEventIdentifiers.map { String(describing: type(of: $0)) }
        #expect(!names.contains(closeEventName))
        alert.dismiss(animated: false)
    }

    @Test func exportTapPassesBarButtonItemAsSender() throws {
        let fixture = Self.makeFixture(accessLevel: .owner)
        Self.configure(fixture.sut, mode: .view, accessLevel: .owner)
        let exportItem = try #require(fixture.sut.toolbarItems?.last)
        Self.fire(exportItem)
        #expect(fixture.router.exportFile_calledTimes == 1)
        #expect(fixture.router.exportFile_sender as? UIBarButtonItem === exportItem)
    }

    @Test func editTapTracksExistingEvents() throws {
        let fixture = Self.makeFixture(accessLevel: .owner)
        Self.configure(fixture.sut, mode: .view, accessLevel: .owner)
        let editItem = try #require(fixture.sut.toolbarItems?[2])
        Self.fire(editItem)
        let names = fixture.tracker.trackedEventIdentifiers.map { String(describing: type(of: $0)) }
        #expect(names.contains("MEGAAOSTextEditorEditMenuToolbarEvent"))
        #expect(names.contains("MEGAAOSEditTextFileActionEvent"))
    }

    // MARK: - Top bar

    @available(iOS 26.0, *)
    @Test func configViewStylesGlassNavigationBarOnIOS26() {
        let fixture = Self.makeFixture()
        let nav = UINavigationController(rootViewController: fixture.sut)
        nav.navigationBar.backgroundColor = .red
        Self.configure(fixture.sut, mode: .view)
        #expect(nav.navigationBar.isTranslucent)
        #expect(nav.navigationBar.backgroundColor == .clear)
    }

    @available(iOS 26.0, *)
    @Test func colorAppearanceChangeRestylesGlassNavigationBar() {
        let fixture = Self.makeFixture()
        let nav = UINavigationController(rootViewController: fixture.sut)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        Self.configure(fixture.sut, mode: .view)
        nav.navigationBar.backgroundColor = .red

        window.overrideUserInterfaceStyle = .dark
        window.layoutIfNeeded()

        #expect(nav.navigationBar.backgroundColor == .clear)
    }

    // MARK: - Edit mode

    @Test func editModeSetsCancelSaveAndModeItems() throws {
        let fixture = Self.makeFixture(mode: .edit)

        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        #expect(fixture.sut.contentState.screen == .editor)
        #expect(fixture.sut.navigationItem.leftBarButtonItem?.title == Strings.Localizable.cancel)
        let right = try #require(fixture.sut.navigationItem.rightBarButtonItems)
        #expect(right.count == 2)
        #expect(right.first?.title == Strings.Localizable.save)
        #expect(right.last?.menu != nil)
    }

    /// Save is bold and keeps the callout size of the default text size (16 pt), also at a larger text size.
    @Test(arguments: [TextEditorMode.edit, .create])
    func editingNavItemsAreCancelAndBoldSaveOfOneSize(mode: TextEditorMode) throws {
        let fixture = Self.makeFixture(mode: mode)

        Self.configure(fixture.sut, mode: mode, accessLevel: nil)

        #expect(fixture.sut.navigationItem.leftBarButtonItem?.title == Strings.Localizable.cancel)
        let save = try #require(fixture.sut.navigationItem.rightBarButtonItems?.first)
        #expect(save.title == Strings.Localizable.save)
        let font = try #require(save.titleTextAttributes(for: .normal)?[.font] as? UIFont)
        #expect(font.pointSize == 16)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    @Test func modeItemReadsMoreWithModeValue() throws {
        let fixture = Self.makeFixture(mode: .edit)

        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        let item = try #require(Self.modeItem(of: fixture.sut))
        #expect(item.accessibilityLabel == Strings.Localizable.more)
        #expect(item.accessibilityValue == Strings.Localizable.MarkdownEditor.Mode.richText)
    }

    @Test func modeMenuChecksActiveMode() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        let menu = try #require(Self.modeItem(of: fixture.sut)?.menu)
        let states = menu.children.compactMap { ($0 as? UIAction)?.state }

        // Plain text is off and Rich text is on, because Edit opens in rich mode.
        #expect(states == [.off, .on])
    }

    @Test func choosingPlainTextSetsPlainTextMode() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)
        let menu = try #require(Self.modeItem(of: fixture.sut)?.menu)
        let plainText = try #require(menu.children.first as? UIAction)

        plainText.performWithSender(nil, target: nil)

        #expect(fixture.sut.contentState.textEditorMode == .plainText)
    }

    @Test func choosingPlainTextTracksPlainTextModeEventOnce() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        try Self.performModeAction(.plainText, in: fixture)

        #expect(Self.trackedEventNames(fixture) == [String(describing: TextEditorPlainTextModeMenuItemEvent.self)])
    }

    @Test func choosingRichTextTracksRichTextModeEventOnce() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)
        fixture.sut.contentState.textEditorMode = .plainText

        try Self.performModeAction(.richText, in: fixture)

        #expect(Self.trackedEventNames(fixture) == [String(describing: TextEditorRichTextModeMenuItemEvent.self)])
    }

    @Test func choosingTheActiveModeTracksOneEvent() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)

        try Self.performModeAction(.richText, in: fixture)

        #expect(Self.trackedEventNames(fixture) == [String(describing: TextEditorRichTextModeMenuItemEvent.self)])
    }

    private static func performModeAction(_ mode: MarkdownTextEditorMode, in fixture: Fixture) throws {
        let menu = try #require(modeItem(of: fixture.sut)?.menu)
        let action = try #require(menu.children.compactMap { $0 as? UIAction }.first { $0.title == mode.title })
        action.performWithSender(nil, target: nil)
    }

    private static func trackedEventNames(_ fixture: Fixture) -> [String] {
        // The screen event from setting up the view is not a mode event.
        fixture.tracker.trackedEventIdentifiers
            .map { String(describing: type(of: $0)) }
            .filter { $0.hasSuffix("ModeMenuItemEvent") }
    }

    @Test func saveTapUploadsEditorText() async throws {
        let fixture = Self.makeFixture(mode: .edit, content: "old", parentHandle: 55)
        try await Self.waitForSetUp(fixture.sut)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil, content: "old")
        fixture.sut.contentState.text = "# New text"
        let save = try #require(fixture.sut.navigationItem.rightBarButtonItems?.first { $0.title == Strings.Localizable.save })

        Self.fire(save)

        let uploaded = try String(contentsOf: fixture.upload.tempURL(forFilename: "notes.md"), encoding: .utf8)
        #expect(uploaded == "# New text")
    }

    @Test func saveTapUploadsEditTheEditorHasNotWrittenYet() async throws {
        let fixture = Self.makeFixture(mode: .edit, fileName: "pending.md", content: "# Title\n", parentHandle: 55)
        let window = Self.makeSceneWindow(rootViewController: UINavigationController(rootViewController: fixture.sut))
        defer { window.isHidden = true }
        try await Self.waitForSetUp(fixture.sut)
        fixture.sut.contentState.textEditorMode = .plainText
        try await Self.waitUntil { Self.sourceTextView(in: window) != nil }
        let textView = try #require(Self.sourceTextView(in: window))
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        // The editor writes this key to the state only after an idle delay, so Save must flush it.
        textView.insertText("x")
        let save = try #require(fixture.sut.navigationItem.rightBarButtonItems?.first { $0.title == Strings.Localizable.save })

        Self.fire(save)

        let uploaded = try String(contentsOf: fixture.upload.tempURL(forFilename: "pending.md"), encoding: .utf8)
        #expect(uploaded == "# Title\nx")
    }

    @Test func cancelWithChangesShowsDiscardPrompt() async throws {
        let fixture = Self.makeFixture(mode: .edit, content: "saved")
        try await Self.waitForSetUp(fixture.sut)
        let nav = UINavigationController(rootViewController: fixture.sut)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil, content: "saved")
        fixture.sut.contentState.text = "changed"
        let cancel = try #require(fixture.sut.navigationItem.leftBarButtonItem)

        Self.fire(cancel)
        try await Self.waitUntil { fixture.sut.presentedViewController != nil }

        #expect(fixture.sut.presentedViewController is UIAlertController)
        // The prompt asks first. The screen stays in the editor.
        #expect(fixture.sut.contentState.screen == .editor)
    }

    @Test func cancelWithoutChangesReturnsToPreview() async throws {
        let fixture = Self.makeFixture(mode: .edit, content: "saved")
        try await Self.waitForSetUp(fixture.sut)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil, content: "saved")
        let cancel = try #require(fixture.sut.navigationItem.leftBarButtonItem)

        Self.fire(cancel)
        try await Self.waitUntil { fixture.sut.contentState.screen == .preview }

        #expect(fixture.sut.contentState.screen == .preview)
        #expect(fixture.sut.presentedViewController == nil)
        #expect(fixture.sut.contentState.text == "saved")
    }

    @Test func discardConfirmReturnsToPreviewWithFileText() async throws {
        let fixture = Self.makeFixture(mode: .edit, content: "saved")
        try await Self.waitForSetUp(fixture.sut)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil, content: "saved")
        fixture.sut.contentState.text = "changed"

        // The discard action of the prompt sends this action.
        fixture.viewModel.dispatch(.cancel)
        try await Self.waitUntil { fixture.sut.contentState.screen == .preview }

        #expect(fixture.sut.contentState.screen == .preview)
        #expect(fixture.sut.contentState.text == "saved")
    }

    @Test func editAfterOpenOnCachedFileOpensEditor() async throws {
        let fixture = Self.makeFixture(mode: .view, content: "cached")
        try await Self.waitForSetUp(fixture.sut)

        fixture.sut.editAfterOpen()
        try await Self.waitUntil { fixture.sut.contentState.screen == .editor }

        #expect(fixture.sut.contentState.screen == .editor)
        #expect(fixture.sut.contentState.text == "cached")
        #expect(fixture.sut.navigationItem.leftBarButtonItem?.title == Strings.Localizable.cancel)
    }

    // MARK: - Mode menu

    @Test func modeMenuListsPlainTextThenRichText() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)
        let menu = try #require(Self.modeItem(of: fixture.sut)?.menu)
        let titles = menu.children.compactMap { ($0 as? UIAction)?.title }
        #expect(titles == [Strings.Localizable.MarkdownEditor.Mode.plainText, Strings.Localizable.MarkdownEditor.Mode.richText])
    }

    @Test func choosingPlainTextUpdatesModeItemValue() throws {
        let fixture = Self.makeFixture(mode: .edit)
        Self.configure(fixture.sut, mode: .edit, accessLevel: nil)
        #expect(Self.modeItem(of: fixture.sut)?.accessibilityValue == Strings.Localizable.MarkdownEditor.Mode.richText)

        let menu = try #require(Self.modeItem(of: fixture.sut)?.menu)
        let plainText = try #require(menu.children.first as? UIAction)
        plainText.performWithSender(nil, target: nil)

        #expect(Self.modeItem(of: fixture.sut)?.accessibilityValue == Strings.Localizable.MarkdownEditor.Mode.plainText)
    }

    // MARK: - Save

    @Test func createModeSaveUploadsToParentFolder() throws {
        let fixture = Self.makeFixture(mode: .create, fileName: "n.md", parentHandle: 55, nodeEntity: nil)
        Self.configure(fixture.sut, mode: .create, accessLevel: nil, fileName: "n.md")
        fixture.sut.contentState.text = "# Hello"
        let save = try #require(fixture.sut.navigationItem.rightBarButtonItems?.first { $0.title == Strings.Localizable.save })

        Self.fire(save)

        #expect(fixture.upload.hasExistFileParentHandles == [55])
        #expect(fixture.upload.newName == "n.md")
    }

    // MARK: - Lifetime

    @Test func closingReleasesScreenAndState() {
        weak var weakScreen: MarkdownTextEditorViewController?
        weak var weakState: MarkdownTextEditorContentState?
        autoreleasepool {
            let fixture = Self.makeFixture()
            weakScreen = fixture.sut
            weakState = fixture.sut.contentState
        }
        #expect(weakScreen == nil)
        #expect(weakState == nil)
    }
}
