import MEGADomain

package protocol TransferControlUseCaseProtocol: Sendable {
    /// Pauses a single in-flight transfer
    func pauseTransfer(_ transfer: TransferEntity) async throws
    /// Resumes a single paused transfer
    func resumeTransfer(_ transfer: TransferEntity) async throws
    /// Retries a finished (failed or cancelled) transfer. Retry re-queues a fresh transfer with the
    /// same parameters and it runs on the Active tab; callers need not distinguish it from a new transfer.
    func retryTransfer(_ transfer: TransferEntity) async throws
    /// Cancels a single in-flight transfer. The transfer finishes as Cancelled.
    func cancelTransfer(_ transfer: TransferEntity) async throws
    /// Re-queues the retryable transfers among the given tags (uploads whose staged
    /// source is gone are skipped). The caller scopes `tags` to the Failed tab's
    /// rows. Returns the re-queued tags, so the caller can clear their entries.
    func retryTransfers(tags: Set<Int>) -> Set<Int>
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

    package func retryTransfer(_ transfer: TransferEntity) async throws {
        try await repo.retryTransfer(transfer)
    }

    package func cancelTransfer(_ transfer: TransferEntity) async throws {
        try await repo.cancelTransfer(transfer)
    }

    package func retryTransfers(tags: Set<Int>) -> Set<Int> {
        repo.retryTransfers(tags: tags)
    }
}
