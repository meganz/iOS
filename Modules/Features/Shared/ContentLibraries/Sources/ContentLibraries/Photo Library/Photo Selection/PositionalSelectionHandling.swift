import Combine
import Foundation
import MEGADomain

/// A position in the grid as the user is looking at it.
///
/// The sections reach the collection view through a debounce, so for a moment after the library
/// changes the screen still shows the previous one. An index read off that screen and answered
/// against the newer library names a different photo; the version is what tells the two apart.
public struct SelectionPosition: Hashable, Sendable {
    /// Index into the library's flat photo order, placeholders included.
    public let flatIndex: Int

    /// Opaque here: the grid takes it with the data it renders and hands it back untouched.
    public let layoutVersion: Int

    public init(flatIndex: Int, layoutVersion: Int) {
        self.flatIndex = flatIndex
        self.layoutVersion = layoutVersion
    }
}

/// What the grid did to one cell.
public enum PhotoSelectionInteraction: Sendable, Equatable {
    case tap
    case longPress
    case dragSelect
    case dragDeselect
}

/// Identifies one drag, finger down to finger up. What it started from is remembered by the
/// handler, the side that can keep that record true as the library changes underneath it.
public struct SelectionGestureToken: Hashable, Sendable {
    public let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

/// Selection for cells that have no node yet.
///
/// A grid keys selection by handle, which a placeholder has none of. A screen that pages its content
/// in answers for those slots itself, and this is the whole of what the grid asks it: positions and
/// opaque tokens out, never a coordinate of the screen's own.
@MainActor
public protocol PositionalSelectionHandling: AnyObject {
    /// Fires when the positional selection changes, so a placeholder cell can re-read its mark.
    var selectionDidChangePublisher: AnyPublisher<Void, Never> { get }

    func isSelected(at position: SelectionPosition) -> Bool

    func apply(_ interaction: PhotoSelectionInteraction, at position: SelectionPosition)

    /// Take a record of what is selected now, for the drag that is starting.
    func beginSelectionGesture() -> SelectionGestureToken

    /// Whether `position` was selected when the drag began — asked when the band shrinks back over
    /// a cell, which then returns to what it was rather than being cleared.
    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, at position: SelectionPosition) -> Bool

    /// The same question for a cell whose photo has loaded. It cannot be answered from the handles
    /// selected at `.began` alone: this cell may have been marked then as a slot with no photo yet,
    /// and resolved into this node since. Only the handler sees that happen, so it keeps both halves
    /// of the record and answers for both.
    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, handle: HandleEntity) -> Bool

    func endSelectionGesture(_ token: SelectionGestureToken)

    /// Keeps the drag that may follow the same unlifted finger from toggling `position` back off.
    func markRecentlyLongPressed(at position: SelectionPosition)

    func wasRecentlyLongPressed(at position: SelectionPosition) -> Bool

    func consumeRecentLongPressMark()
}

/// One placeholder cell's link to the handler. The position is resolved when asked, not when the
/// cell is built: cells are reused and shift, so the answer has to say where this one is now.
@MainActor
public struct PlaceholderCellSelection {
    public let handler: any PositionalSelectionHandling
    public let position: @MainActor () -> SelectionPosition?

    public init(
        handler: any PositionalSelectionHandling,
        position: @escaping @MainActor () -> SelectionPosition?
    ) {
        self.handler = handler
        self.position = position
    }
}
