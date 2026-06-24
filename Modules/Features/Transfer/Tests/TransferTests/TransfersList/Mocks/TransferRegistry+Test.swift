@testable import Transfer

extension TransferRegistry {
    /// Test convenience: builds a registry with no-op collaborators for tests that
    /// only exercise row-state upserts, not per-row actions.
    convenience init() {
        self.init(
            controlUseCase: MockTransferControlUseCase(),
            rowRouter: MockTransferRowRouting(),
            clearTransfersUseCase: MockClearTransfersUseCase()
        )
    }
}
