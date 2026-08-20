import FileLink
import MEGADomain

final class MockFileLinkActionHandler: FileLinkActionHandlerProtocol {
    struct Handled: Equatable {
        let action: FileLinkAction
        let nodeHandle: HandleEntity
    }

    private(set) var handledActions: [Handled] = []
    /// Runs while an action is in flight, so a test can act on the screen before it finishes.
    var whileHandling: (@MainActor () async -> Void)?

    func handle(_ action: FileLinkAction, nodeHandle: HandleEntity) async {
        handledActions.append(Handled(action: action, nodeHandle: nodeHandle))
        await whileHandling?()
    }
}
