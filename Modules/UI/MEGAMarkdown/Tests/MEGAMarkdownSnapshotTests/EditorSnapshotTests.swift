@testable import MEGAMarkdown
@testable import MEGAMarkdownEditor
import MEGASnapshot
import SwiftUI
import Testing
import UIKit

/// `MarkdownEditor` and its controls, 402 wide. Text size, direction and color scheme come only from the SwiftUI environment.
/// Each list test records left to right, then right to left as `<test name>RightToLeft`.
@MainActor
@Suite(.serialized, .snapshot)
struct EditorSnapshotTests {
    /// Every row kind the editor draws: text rows, lists, quotes, code, a divider and raw blocks.
    private static let rowKinds = """
    # Heading 1
    ## Heading 2
    ### Heading 3

    A paragraph with **bold**, *italic*, <u>underline</u>, ~~strikethrough~~, `inline code` and a [link](https://mega.io).

    - Bullet one
    - Bullet two
      - Nested bullet
        1. Third level

    998. Ordered
    999. Ordered

    - [ ] Task to do
    - [x] Task done

    > A quote
    > > Nested quote

    ```swift
    let greeting = "Hello"
    ```

    ---

    | Left | Right |
    |:-----|------:|
    | a    | b     |

    <div>raw HTML</div>
    """

    /// The blocks both the preview and the editor draw the same way. Code lines stay short: the editor wraps them,
    /// the preview scrolls them sideways.
    private static let parity = """
    # Heading 1
    ## Heading 2

    A paragraph with **bold**, *italic*, `inline code`, ~~strikethrough~~ and a [link](https://mega.io).

    - Bullet one
    - Bullet two
      - Nested bullet

    3. Ordered three
    4. Ordered four

    - [ ] Task to do
    - [x] Task done

    > A quote with *emphasis*.

    ```swift
    let greeting = "Hello"
    ```

    ---

    | Left | Center | Right |
    |:-----|:------:|------:|
    | a    | b      | c     |
    """

    private func editor(_ markdown: String, mode: MarkdownEditorMode = .rich) -> some View {
        MarkdownEditor(markdown: .constant(markdown), mode: .constant(mode))
    }

    private func assertList(
        _ view: some View,
        width: CGFloat = 402,
        height: CGFloat,
        dynamicType: DynamicTypeSize = .large,
        bothDirections: Bool = true,
        makeReady: () -> @MainActor (UIWindow) -> Bool = { Self.readyCheck() },
        testName: String = #function,
        line: UInt = #line
    ) async {
        await assertHostedSnapshot(
            of: view, width: width, height: height, dynamicType: dynamicType, isReady: makeReady(), testName: testName, line: line
        )
        guard bothDirections else { return }
        await assertHostedSnapshot(
            of: view,
            width: width,
            height: height,
            dynamicType: dynamicType,
            layoutDirection: .rightToLeft,
            isReady: makeReady(),
            testName: testName.replacingOccurrences(of: "()", with: "") + "RightToLeft",
            line: line
        )
    }

    /// True once a row list is on screen, its visible rows are measured, and it did not move for 3 checks in a row.
    private static func readyCheck() -> @MainActor (UIWindow) -> Bool {
        var last = ""
        var stableChecks = 0
        return { window in
            guard let list = list(in: window), let layout = list.collectionViewLayout as? MarkdownRowLayout else { return false }
            list.setNeedsLayout()
            list.layoutIfNeeded()
            let items = list.indexPathsForVisibleItems.map(\.item).sorted()
            guard !items.isEmpty, items.allSatisfy({ layout.heights.isMeasured($0) }) else {
                stableChecks = 0
                return false
            }
            let state = "\(list.contentOffset.y) \(list.contentSize) \(items)"
            stableChecks = state == last ? stableChecks + 1 : 0
            last = state
            return stableChecks >= 3
        }
    }

    private static func list(in window: UIWindow) -> MarkdownRowListView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let list = view as? MarkdownRowListView { return list }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// The source mode views show no list. The limit check runs off the main thread, so they wait 1 s.
    private static func afterOneSecond() -> @MainActor (UIWindow) -> Bool {
        let start = ContinuousClock.now
        return { window in
            window.layoutIfNeeded()
            return ContinuousClock.now - start > .seconds(1)
        }
    }

    // MARK: - Rows

    @Test func editorRowKinds() async {
        await assertList(editor(Self.rowKinds), height: 1_300)
    }

    @Test func editorRowsAccessibilityTextSize() async {
        await assertList(editor("# Title\n\nSome text.\n\n- [ ] A task\n- An item\n\n> A quote"), height: 900, dynamicType: .accessibility3)
    }

    /// A phone in a small size and an iPad in portrait.
    @Test func editorRowKindsNarrow() async {
        await assertList(editor(Self.rowKinds), width: 320, height: 1_500)
    }

    @Test func editorRowKindsIPad() async {
        await assertList(editor(Self.rowKinds), width: 834, height: 1_000)
    }

    // MARK: - Parity with the preview

    /// The same Markdown in the preview. Compare with `editorParity`: only the differences listed in EDITOR-UI.md ("Differences from the preview") may show.
    @Test func previewParity() async {
        await assertList(MarkdownPreview(Self.parity), height: 1_000, bothDirections: false)
    }

    @Test func editorParity() async {
        await assertList(editor(Self.parity), height: 1_000, bothDirections: false)
    }

    /// The preview and the editor draw these blocks the same way. The two reference images may differ by
    /// edge pixels of the text only, so a wrong spacing, size or color shows here.
    @Test(arguments: ["light", "dark"])
    func parityReferencesMatch(_ scheme: String) throws {
        let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("__Snapshots__/EditorSnapshotTests")
        let preview = try Self.pixels(folder.appendingPathComponent("previewParity.\(scheme).png"))
        let editor = try Self.pixels(folder.appendingPathComponent("editorParity.\(scheme).png"))
        #expect(preview.count == editor.count)
        var different = 0
        for index in stride(from: 0, to: min(preview.count, editor.count), by: 4) {
            let delta = (0..<3).map { abs(Int(preview[index + $0]) - Int(editor[index + $0])) }.max() ?? 0
            if delta > 24 { different += 1 }
        }
        let share = Double(different) / Double(preview.count / 4)
        #expect(share < 0.01, "\(share * 100) % of the pixels differ")
    }

    private static func pixels(_ url: URL) throws -> [UInt8] {
        let image = try #require(UIImage(contentsOfFile: url.path)?.cgImage, "no image at \(url.path)")
        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(
            data: &data, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return data
    }

    // MARK: - Controls

    private func model(_ markdown: String, selection: RichSelection) -> RichEditorModel {
        var editor = RichEditor(markdown: markdown)
        editor.select(selection)
        let model = RichEditorModel(editor: editor)
        model.setFocused(true)
        return model
    }

    @Test func toolbar() {
        let model = model("A **bold** word\n\n- item", selection: .caret(RichPosition(blockIndex: 0, offset: 4)))
        assertSnapshot(of: RichFormattingToolbar(model: model).padding(16), height: 90)
    }

    @Test func toolbarRightToLeft() {
        let model = model("A **bold** word\n\n- item", selection: .caret(RichPosition(blockIndex: 0, offset: 4)))
        assertSnapshot(of: RichFormattingToolbar(model: model).padding(16), height: 90, layoutDirection: .rightToLeft)
    }

    @Test func toolbarAccessibilityTextSize() {
        let model = model("A **bold** word\n\n- item", selection: .caret(RichPosition(blockIndex: 0, offset: 4)))
        assertSnapshot(of: RichFormattingToolbar(model: model).padding(16), height: 160, dynamicType: .accessibility3)
    }

    // MARK: - Focus and selection

    /// Selects `selection`, or everything when it is nil, and gives the editor the focus.
    private func focusedEditor(_ markdown: String, selection: RichSelection?) throws -> some View {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else { throw SnapshotSetupError() }
        let model = RichEditorModel(editor: load.editor)
        if let selection { model.select(selection) } else { model.selectAll() }
        model.setFocused(true)
        // The hosted window has a status bar inset on top. Without this the toolbar at the bottom is cut off.
        return RichEditorView(adapter: RichRowAdapter(model: model, load: load), baseURL: nil).ignoresSafeArea(edges: .top)
    }

    private struct SnapshotSetupError: Error {}

    /// A row with the caret shows the formatting toolbar above the keyboard.
    @Test func focusedRowShowsTheToolbar() async throws {
        let view = try focusedEditor("# Title\n\nSome *text* here.", selection: .caret(RichPosition(blockIndex: 1, offset: 5)))
        await assertList(view, height: 700)
    }

    /// Select All marks the divider and the raw blocks as selected.
    @Test func selectedDividerAndRawBlocks() async throws {
        let markdown = "Text\n\n---\n\n| a |\n|---|\n| b |\n\n<div>raw HTML</div>"
        let view = try focusedEditor(markdown, selection: nil)
        await assertList(view, height: 700)
    }

    // MARK: - After an edit

    /// Ready once the list is steady, the row with `row` as text took `text` as typed, and the list is steady again.
    /// The keyboard focus ends before the image, so the image does not depend on the blink of the caret.
    private static func readyAfterTyping(_ text: String, inRowWithText row: String) -> @MainActor (UIWindow) -> Bool {
        weak var lastWindow: UIWindow?
        var hasTyped = false
        var hasEnded = false
        var steady = readyCheck()
        return { window in
            if lastWindow !== window {
                lastWindow = window
                hasTyped = false
                hasEnded = false
                steady = readyCheck()
            }
            guard steady(window) else { return false }
            let textViews = richTextViews(in: window)
            guard hasTyped else {
                guard let textView = textViews.first(where: { $0.text == row }) else { return false }
                type(text, into: textView)
                hasTyped = true
                steady = readyCheck()
                return false
            }
            guard hasEnded else {
                window.endEditing(true)
                hasEnded = true
                steady = readyCheck()
                return false
            }
            return true
        }
    }

    private static func richTextViews(in window: UIWindow) -> [RichTextView] {
        var found: [RichTextView] = []
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            guard !view.isHidden else { continue }
            if let textView = view as? RichTextView { found.append(textView) }
            pending.append(contentsOf: view.subviews)
        }
        return found
    }

    /// Puts the caret at the end of the row and types like the keyboard: it asks the delegate first.
    private static func type(_ text: String, into textView: RichTextView) {
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        if textView.delegate?.textView?(textView, shouldChangeTextIn: textView.selectedRange, replacementText: text) ?? true {
            textView.insertText(text)
        }
    }

    /// Text typed after inline code keeps the chip, the line height and the baseline in every row kind.
    @Test func editorTextTypedAfterInlineCode() async {
        let markdown = "A paragraph with `code`\n\n- Item with `code`\n\n> Quote with `code`\n\nPlain text."
        await assertList(editor(markdown), height: 500, makeReady: { Self.readyAfterTyping(" and more", inRowWithText: "A paragraph with code") })
    }

    @Test func editorTextTypedAfterInlineCodeAccessibilityTextSize() async {
        await assertList(
            editor("A paragraph with `code`\n\nPlain text."),
            height: 600,
            dynamicType: .accessibility3,
            makeReady: { Self.readyAfterTyping(" and more", inRowWithText: "A paragraph with code") }
        )
    }

    /// Enter in an empty list item steps the row out of the list. It draws no marker and the rows below move up.
    @Test func editorEnterInAnEmptyListItem() async {
        await assertList(
            editor("- one\n- two\n-\n\nAfter the list."),
            height: 400,
            makeReady: { Self.readyAfterTyping("\n", inRowWithText: "") }
        )
    }

    // MARK: - Notices

    @Test func fileTooLargeForRichMode() async {
        let markdown = String(repeating: "Some words.\n", count: MarkdownEditor.richModeCharacterLimit / 12 + 1)
        await assertHostedSnapshot(of: editor(markdown), height: 300, isReady: Self.afterOneSecond())
    }

    @Test func sourceModeShowsNormalText() async {
        await assertHostedSnapshot(of: editor("# Title\n\nSome **text**.\n\n- item", mode: .source), height: 300, isReady: Self.afterOneSecond())
    }

    /// One paragraph over the block limit opens as source with a notice. The load takes longer than the limit check.
    @Test func blockTooLongForRichMode() async {
        let line = String(repeating: "a", count: 99)
        let markdown = "# Title\n\n" + Array(repeating: line, count: RichEditorLoad.maxBlockLength / 100 + 1).joined(separator: "\n")
        await assertHostedSnapshot(of: editor(markdown), height: 300, isReady: Self.afterOneSecond())
    }

    @Test func lineTooLongToEdit() async {
        let markdown = String(repeating: "x", count: SourceTextLimit.maxLineLength + 1)
        await assertHostedSnapshot(of: editor(markdown, mode: .source), height: 300, isReady: Self.afterOneSecond())
    }
}
