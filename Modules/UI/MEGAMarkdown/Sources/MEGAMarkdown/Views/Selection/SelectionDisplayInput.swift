import UIKit

/// A caret place in a list of rows: a row (a block of the editor, an item of the preview) and an offset in it.
package struct SelectionPoint: Hashable, Comparable, Sendable {
    package var row: Int
    package var offset: Int

    package init(row: Int, offset: Int) {
        self.row = row
        self.offset = offset
    }

    package static func < (lhs: SelectionPoint, rhs: SelectionPoint) -> Bool {
        (lhs.row, lhs.offset) < (rhs.row, rhs.offset)
    }
}

/// A range between two points. `start` is never after `end`.
package struct SelectionSpan: Hashable, Sendable {
    package let start: SelectionPoint
    package let end: SelectionPoint

    package init(_ first: SelectionPoint, _ second: SelectionPoint) {
        start = min(first, second)
        end = max(first, second)
    }
}

/// A caret position for `SelectionDisplayInput`.
final class SelectionTextPosition: UITextPosition {
    let point: SelectionPoint

    init(_ point: SelectionPoint) {
        self.point = point
    }
}

final class SelectionTextRange: UITextRange {
    let span: SelectionSpan
    private let startPosition: SelectionTextPosition
    private let endPosition: SelectionTextPosition

    init(_ span: SelectionSpan) {
        self.span = span
        startPosition = SelectionTextPosition(span.start)
        endPosition = SelectionTextPosition(span.end)
    }

    override var start: UITextPosition { startPosition }
    override var end: UITextPosition { endPosition }
    override var isEmpty: Bool { span.start == span.end }
}

/// One rect of the highlight, in the list view.
package final class SelectionRect: UITextSelectionRect {
    private let frame: CGRect
    private let direction: NSWritingDirection
    private let isStart: Bool
    private let isEnd: Bool

    package init(frame: CGRect, direction: NSWritingDirection, isStart: Bool, isEnd: Bool) {
        self.frame = frame
        self.direction = direction
        self.isStart = isStart
        self.isEnd = isEnd
    }

    override package var rect: CGRect { frame }
    override package var writingDirection: NSWritingDirection { direction }
    override package var containsStart: Bool { isStart }
    override package var containsEnd: Bool { isEnd }
    override package var isVertical: Bool { false }
}

/// The geometry of a selection over rows, from the rows that are on screen.
@MainActor
package protocol SelectionGeometrySource: AnyObject {
    /// The caret of `point` in the list view, or nil when its row has no cell.
    func caretRect(for point: SelectionPoint) -> CGRect?
    /// The highlight rects of `span` in the rows on screen, in the list view.
    func selectionRects(for span: SelectionSpan) -> [UITextSelectionRect]
}

/// The smallest `UITextInput` that lets `UITextSelectionDisplayInteraction` draw a selection over rows.
/// Only the selection and its geometry are real. It never edits text and never becomes first responder.
@MainActor
package final class SelectionDisplayInput: UIResponder, UITextInput {
    package weak var geometry: (any SelectionGeometrySource)?
    /// The view whose coordinates the rects use. Without it the system places every rect in other coordinates.
    package weak var hostView: UIView?
    package var span: SelectionSpan?

    override package init() {
        super.init()
    }

    package var textInputView: UIView { hostView ?? UIView() }

    package var selectedTextRange: UITextRange? {
        get { span.map(SelectionTextRange.init) }
        set { span = (newValue as? SelectionTextRange)?.span }
    }

    package func caretRect(for position: UITextPosition) -> CGRect {
        guard let position = position as? SelectionTextPosition else { return .null }
        return geometry?.caretRect(for: position.point) ?? .null
    }

    package func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard let range = range as? SelectionTextRange else { return [] }
        return geometry?.selectionRects(for: range.span) ?? []
    }

    package func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let from = fromPosition as? SelectionTextPosition, let to = toPosition as? SelectionTextPosition else { return nil }
        return SelectionTextRange(SelectionSpan(from.point, to.point))
    }

    package func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard let lhs = (position as? SelectionTextPosition)?.point, let rhs = (other as? SelectionTextPosition)?.point else {
            return .orderedSame
        }
        if lhs < rhs { return .orderedAscending }
        return lhs == rhs ? .orderedSame : .orderedDescending
    }

    // MARK: - Not used: the display interaction draws only

    package var markedTextRange: UITextRange? { nil }
    package var markedTextStyle: [NSAttributedString.Key: Any]?
    package var inputDelegate: (any UITextInputDelegate)?
    package lazy var tokenizer: any UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)
    package var beginningOfDocument: UITextPosition { SelectionTextPosition(SelectionPoint(row: 0, offset: 0)) }
    package var endOfDocument: UITextPosition { SelectionTextPosition(span?.end ?? SelectionPoint(row: 0, offset: 0)) }
    package var hasText: Bool { true }
    package func text(in range: UITextRange) -> String? { nil }
    package func replace(_ range: UITextRange, withText text: String) {}
    package func setMarkedText(_ markedText: String?, selectedRange: NSRange) {}
    package func unmarkText() {}
    package func position(from position: UITextPosition, offset: Int) -> UITextPosition? { nil }
    package func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? { nil }
    package func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int { 0 }
    package func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? { nil }
    package func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? { nil }
    package func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection { .natural }
    package func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {}
    package func firstRect(for range: UITextRange) -> CGRect { .null }
    package func closestPosition(to point: CGPoint) -> UITextPosition? { nil }
    package func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? { nil }
    package func characterRange(at point: CGPoint) -> UITextRange? { nil }
    package func insertText(_ text: String) {}
    package func deleteBackward() {}
}
