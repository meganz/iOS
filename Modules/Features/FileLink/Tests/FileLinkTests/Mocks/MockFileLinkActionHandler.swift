import FileLink
import MEGADomain

final class MockFileLinkActionHandler: FileLinkActionHandlerProtocol {
    struct Handled: Equatable {
        let action: FileLinkAction
        let nodeHandle: HandleEntity
    }

    private(set) var handledActions: [Handled] = []

    func handle(_ action: FileLinkAction, nodeHandle: HandleEntity) async {
        handledActions.append(Handled(action: action, nodeHandle: nodeHandle))
    }
}
