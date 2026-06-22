@testable import Transfer

extension TransferRegistry {
    /// Test convenience: builds a registry with a no-op control use case for
    /// tests that only exercise row-state upserts, not per-row pause/resume.
    convenience init() {
        self.init(controlUseCase: MockTransferControlUseCase())
    }
}
