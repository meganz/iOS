import MEGADomain
import Transfer

@MainActor
final class MockTransferRowRouting: TransferRowRouting {
    private(set) var presentActionsTags: [Int] = []
    private(set) var presentActionsContexts: [TransferRowActionContext] = []
    private(set) var openFileTags: [Int] = []
    private(set) var lastOnClear: (@MainActor () -> Void)?
    private(set) var showUpgradeCallCount = 0

    nonisolated init() {}

    func presentActions(for transfer: TransferEntity, context: TransferRowActionContext, onClear: @MainActor @escaping () -> Void) {
        presentActionsTags.append(transfer.tag)
        presentActionsContexts.append(context)
        lastOnClear = onClear
    }

    func openFile(for transfer: TransferEntity) {
        openFileTags.append(transfer.tag)
    }

    func showUpgrade() {
        showUpgradeCallCount += 1
    }
}
