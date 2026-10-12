import MEGASnapshot
@testable import MEGATextEditor
import SwiftUI
import Testing
import UIKit

/// Every test records a light and a dark image of the Markdown file content.
/// A test name ends with the phone and the text size: SE or ProMax, DefaultText or AccessibilityXL.
@MainActor
@Suite(.serialized, .snapshot)
struct MarkdownTextEditorContentViewSnapshotTests {
    private enum Phone {
        case se
        case proMax

        var size: CGSize {
            switch self {
            case .se: CGSize(width: 375, height: 667)
            case .proMax: CGSize(width: 440, height: 956)
            }
        }
    }

    private static let markdown = """
    # Meeting notes

    Plan for **Monday** with a [link](https://mega.nz).

    - First item
    - Second item

    > A short quote.
    """

    private static func makeState(
        screen: MarkdownTextEditorContentState.Screen,
        progress: Double? = nil,
        mode: MarkdownTextEditorMode = .richText
    ) -> MarkdownTextEditorContentState {
        let state = MarkdownTextEditorContentState()
        state.fileName = "Meeting notes.md"
        state.text = markdown
        state.loadingProgress = progress
        if screen == .editor {
            state.showEditor()
            state.textEditorMode = mode
        } else {
            state.screen = screen
        }
        return state
    }

    private static func record(
        _ state: MarkdownTextEditorContentState,
        phone: Phone,
        dynamicType: DynamicTypeSize = .large,
        testName: String = #function
    ) {
        assertSnapshot(
            of: MarkdownTextEditorContentView(state: state),
            width: phone.size.width,
            height: phone.size.height,
            dynamicType: dynamicType,
            testName: testName
        )
    }

    /// Preview and editor fill in after the first frame. The image is taken once no spinner shows,
    /// a text view or a list is on screen, and the picture did not change for 5 checks in a row.
    private static func recordHosted(
        _ state: MarkdownTextEditorContentState,
        phone: Phone,
        dynamicType: DynamicTypeSize = .large,
        testName: String = #function
    ) async {
        var lastPicture = Data()
        var stableChecks = 0
        await assertHostedSnapshot(
            of: MarkdownTextEditorContentView(state: state),
            width: phone.size.width,
            height: phone.size.height,
            dynamicType: dynamicType,
            isReady: { window in
                guard hasContent(in: window) else {
                    stableChecks = 0
                    return false
                }
                window.layoutIfNeeded()
                let picture = UIGraphicsImageRenderer(bounds: window.bounds).image { window.layer.render(in: $0.cgContext) }.pngData() ?? Data()
                stableChecks = picture == lastPicture ? stableChecks + 1 : 0
                lastPicture = picture
                return stableChecks >= 5
            },
            testName: testName
        )
    }

    private static func hasContent(in window: UIWindow) -> Bool {
        var hasScrollView = false
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if view is UIActivityIndicatorView, !view.isHidden { return false }
            if view is UITextView || view is UICollectionView { hasScrollView = true }
            pending.append(contentsOf: view.subviews)
        }
        return hasScrollView
    }

    // MARK: - Loading, progress unknown

    @Test func loadingUnknownProgress_SE_DefaultText() {
        Self.record(Self.makeState(screen: .loading), phone: .se)
    }

    @Test func loadingUnknownProgress_SE_AccessibilityXL() {
        Self.record(Self.makeState(screen: .loading), phone: .se, dynamicType: .accessibility3)
    }

    @Test func loadingUnknownProgress_ProMax_DefaultText() {
        Self.record(Self.makeState(screen: .loading), phone: .proMax)
    }

    @Test func loadingUnknownProgress_ProMax_AccessibilityXL() {
        Self.record(Self.makeState(screen: .loading), phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Loading, half done

    // A progress bar has no text, so the text size does not change it.
    @Test func loadingHalfDone_SE_DefaultText() {
        Self.record(Self.makeState(screen: .loading, progress: 0.5), phone: .se)
    }

    @Test func loadingHalfDone_ProMax_DefaultText() {
        Self.record(Self.makeState(screen: .loading, progress: 0.5), phone: .proMax)
    }

    // MARK: - Preview

    @Test func preview_SE_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .preview), phone: .se)
    }

    @Test func preview_SE_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .preview), phone: .se, dynamicType: .accessibility3)
    }

    @Test func preview_ProMax_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .preview), phone: .proMax)
    }

    @Test func preview_ProMax_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .preview), phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Editor, rich text mode

    @Test func editorRichText_SE_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .editor), phone: .se)
    }

    @Test func editorRichText_SE_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .editor), phone: .se, dynamicType: .accessibility3)
    }

    @Test func editorRichText_ProMax_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .editor), phone: .proMax)
    }

    @Test func editorRichText_ProMax_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .editor), phone: .proMax, dynamicType: .accessibility3)
    }

    // MARK: - Editor, plain text mode

    @Test func editorPlainText_SE_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .editor, mode: .plainText), phone: .se)
    }

    @Test func editorPlainText_SE_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .editor, mode: .plainText), phone: .se, dynamicType: .accessibility3)
    }

    @Test func editorPlainText_ProMax_DefaultText() async {
        await Self.recordHosted(Self.makeState(screen: .editor, mode: .plainText), phone: .proMax)
    }

    @Test func editorPlainText_ProMax_AccessibilityXL() async {
        await Self.recordHosted(Self.makeState(screen: .editor, mode: .plainText), phone: .proMax, dynamicType: .accessibility3)
    }
}
