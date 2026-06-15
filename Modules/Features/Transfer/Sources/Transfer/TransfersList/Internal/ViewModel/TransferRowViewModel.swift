import Foundation
import Search

/// Per-row observable holding the UI state for one transfer. Lives in the
/// `TransferRegistry` keyed by `ResultId`. Live updates mutate a single instance,
/// so SwiftUI re-renders only the observing row view, not the whole list.
@MainActor
public final class TransferRowViewModel: ObservableObject {
    @Published public private(set) var state: TransferRowState

    public init(state: TransferRowState) {
        self.state = state
    }

    func update(state: TransferRowState) {
        self.state = state
    }
}
