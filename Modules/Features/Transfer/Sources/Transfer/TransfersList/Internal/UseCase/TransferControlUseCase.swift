import MEGADomain

package protocol TransferControlUseCaseProtocol: Sendable {
    /// Pauses a single in-flight transfer
    func pauseTransfer(_ transfer: TransferEntity) async throws
    /// Resumes a single paused transfer
    func resumeTransfer(_ transfer: TransferEntity) async throws
}

package struct TransferControlUseCase: TransferControlUseCaseProtocol {
    private let repo: any TransferControlRepositoryProtocol

    package init(repo: some TransferControlRepositoryProtocol) {
        self.repo = repo
    }

    package func pauseTransfer(_ transfer: TransferEntity) async throws {
        try await repo.pauseTransfer(transfer)
    }

    package func resumeTransfer(_ transfer: TransferEntity) async throws {
        try await repo.resumeTransfer(transfer)
    }
}
