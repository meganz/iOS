import MEGAMarkdown
import SwiftUI
import UIKit

/// What a row's text view needs from the editor around it. The row adapter is the host.
@MainActor
protocol RichTextRowHost: AnyObject {
    var model: RichEditorModel { get }
    var modelUndoManager: ModelUndoManager { get }
    /// The model row the text view shows now. Rows move after other edits, so a view never keeps its index.
    func row(of textView: RichTextView) -> Int?
    /// The view's text got more or fewer lines.
    func textViewDidChangeHeight(_ textView: RichTextView)
    /// An arrow key left the text through `edge`.
    func textView(_ textView: RichTextView, didLeaveThrough edge: RichTextView.Edge)
    /// True when ⇧ with an arrow can grow the selection past the row.
    var canExtendSelectionPastEdge: Bool { get }
    /// ⇧ with an arrow at the edge of the text.
    func textView(_ textView: RichTextView, didShiftArrowAtEdge edge: RichTextView.Edge)
    func textViewDidBeginEditing(_ textView: RichTextView)
    func textViewDidEndEditing(_ textView: RichTextView)
    /// Select All in the text view: the whole document, not only the row.
    func textViewDidRequestSelectAll(_ textView: RichTextView)
    /// SwiftUI removes the row's text view, for example for a new nesting level. `hadFocus`: it had the keyboard.
    func textViewWillBeRemoved(_ textView: RichTextView, hadFocus: Bool)
}

/// The editable text of one text or code row.
/// The model is the source of truth. The view takes the model's text only when the row's input is newer
/// than what the view holds, so a key typed in the view is never overwritten by an older input.
/// An input of another row always replaces the text: a reused cell gives its text view a new row.
struct RichTextRow: UIViewRepresentable {
    /// A text or code block.
    let block: RichBlock
    /// The model version this input was read at.
    let version: Int
    /// The row the block belongs to. Nil: the view always shows the same row.
    var id: RichRowID?
    let theme: MarkdownTheme
    let strings: MarkdownEditorStrings
    weak var host: (any RichTextRowHost)?
    /// Only tells SwiftUI that the text size changed, so it updates the row and measures it again.
    /// The text view takes its fonts from its own traits.
    var dynamicTypeSize = DynamicTypeSize.large

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> RichTextView {
        let textView = RichTextView.make()
        textView.delegate = context.coordinator
        textView.accessibilityIdentifier = "editor.row"
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: RichTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.host = host
        coordinator.input = self
        textView.modelUndoManager = host?.modelUndoManager
        textView.indentTitle = strings.indent
        textView.outdentTitle = strings.outdent
        // Code is plain text: no corrections, and it stays left to right, like in the preview.
        let isCode = if case .codeBlock = block { true } else { false }
        textView.autocapitalizationType = isCode ? .none : .sentences
        textView.autocorrectionType = isCode ? .no : .default
        textView.spellCheckingType = isCode ? .no : .default
        textView.smartQuotesType = isCode ? .no : .default
        textView.smartDashesType = isCode ? .no : .default
        textView.semanticContentAttribute = isCode ? .forceLeftToRight : .unspecified
        if case .heading = block {
            textView.accessibilityTraits.insert(.header)
        } else {
            textView.accessibilityTraits.remove(.header)
        }
        coordinator.wireKeys(textView)
        coordinator.apply(force: false)
    }

    static func dismantleUIView(_ textView: RichTextView, coordinator: Coordinator) {
        coordinator.host?.textViewWillBeRemoved(textView, hadFocus: textView.isFirstResponder)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: RichTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let size = uiView.fittingSize(width: width)
        context.coordinator.lastHeight = size.height
        return CGSize(width: width, height: size.height)
    }

    /// The first baseline of a row of `block`, from its top. The list marker lines up with it.
    static func firstBaseline(of block: RichBlock, theme: MarkdownTheme, traits: UITraitCollection) -> CGFloat {
        guard let kind = RichTextStyler.kind(of: block) else { return 0 }
        let resolved = theme.resolved(for: traits)
        let font = RichTextStyler(resolved: resolved, isRightToLeft: false).baseFont(kind)
        let codeSpans = block.richText?.spans.filter { $0.style == .code } ?? []
        return resolved.firstBaseline(
            of: font,
            hasInlineCode: !codeSpans.isEmpty,
            startsWithInlineCode: codeSpans.contains { $0.range.lowerBound == 0 }
        )
    }
}
