import Combine
@testable import ContentLibraries
import MEGADomain

/// Stands in for the screen that answers for cells whose photo has not loaded.
@MainActor
final class MockPositionalSelectionHandler: PositionalSelectionHandling {
    struct Application: Equatable {
        let interaction: PhotoSelectionInteraction
        let position: SelectionPosition
    }

    var selectedPositions: Set<SelectionPosition> = []
    var baselinePositions: Set<SelectionPosition> = []
    var baselineHandles: Set<HandleEntity> = []
    var recentlyLongPressedPositions: Set<SelectionPosition> = []

    private(set) var applied: [Application] = []
    private(set) var longPressMarks: [SelectionPosition] = []
    private(set) var begunGestures = 0
    private(set) var endedGestures: [SelectionGestureToken] = []
    private(set) var baselineHandleQueries: [HandleEntity] = []
    private(set) var consumedLongPressMarks = 0

    private let selectionDidChange = PassthroughSubject<Void, Never>()

    var selectionDidChangePublisher: AnyPublisher<Void, Never> {
        selectionDidChange.eraseToAnyPublisher()
    }

    func notifySelectionChanged() {
        selectionDidChange.send(())
    }

    func isSelected(at position: SelectionPosition) -> Bool {
        selectedPositions.contains(position)
    }

    func apply(_ interaction: PhotoSelectionInteraction, at position: SelectionPosition) {
        applied.append(Application(interaction: interaction, position: position))
    }

    func beginSelectionGesture() -> SelectionGestureToken {
        begunGestures += 1
        return SelectionGestureToken()
    }

    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, at position: SelectionPosition) -> Bool {
        baselinePositions.contains(position)
    }

    func wasSelectedAtGestureStart(_ token: SelectionGestureToken, handle: HandleEntity) -> Bool {
        baselineHandleQueries.append(handle)
        return baselineHandles.contains(handle)
    }

    func endSelectionGesture(_ token: SelectionGestureToken) {
        endedGestures.append(token)
    }

    func markRecentlyLongPressed(at position: SelectionPosition) {
        longPressMarks.append(position)
    }

    func wasRecentlyLongPressed(at position: SelectionPosition) -> Bool {
        recentlyLongPressedPositions.contains(position)
    }

    func consumeRecentLongPressMark() {
        consumedLongPressMarks += 1
    }
}
