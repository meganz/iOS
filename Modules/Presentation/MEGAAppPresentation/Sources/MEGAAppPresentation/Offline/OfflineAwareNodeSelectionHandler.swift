/// Wraps a screen's node selection handler so that, while the new offline mode is on and the
/// device is offline, tapping a file with no local copy shows the "not available offline" snack
/// bar instead of opening nothing (IOS-12409).
@MainActor
public struct OfflineAwareNodeSelectionHandler: NodeSelectionHandling {
    private let handler: any NodeSelectionHandling
    private let tapDispatcher: OfflineAwareNodeTapDispatcher
    public init(
        wrapping handler: any NodeSelectionHandling,
        tapDispatcher: OfflineAwareNodeTapDispatcher
    ) {
        self.handler = handler
        self.tapDispatcher = tapDispatcher
    }

    public func handle(selection: NodeSelection) {
        tapDispatcher.dispatch(nodeHandle: selection.handle, isFolder: selection.isFolder) { _ in
            handler.handle(selection: selection)
        }
    }
}
