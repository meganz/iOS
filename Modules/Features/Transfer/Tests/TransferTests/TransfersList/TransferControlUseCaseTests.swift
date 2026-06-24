import MEGADomain
import MEGADomainMock
import Testing
import Transfer

@Suite("TransferControlUseCase forwards per-transfer pause/resume/retry requests.")
struct TransferControlUseCaseTests {
    private enum TestError: Error, Equatable {
        case pause
        case resume
        case retry
    }

    private static func makeSUT(
        repo: MockTransferControlRepository = .newRepo
    ) -> (sut: TransferControlUseCase, repo: MockTransferControlRepository) {
        (TransferControlUseCase(repo: repo), repo)
    }

    @Test("Pausing a transfer forwards the transfer to the repository")
    func pauseTransfer() async throws {
        let (sut, repo) = Self.makeSUT()
        let transfer = TransferEntity(tag: 1)

        try await sut.pauseTransfer(transfer)

        #expect(repo.pausedTransfers.map(\.tag) == [1])
        #expect(repo.resumedTransfers.isEmpty)
    }

    @Test("Resuming a transfer forwards the transfer to the repository")
    func resumeTransfer() async throws {
        let (sut, repo) = Self.makeSUT()
        let transfer = TransferEntity(tag: 2)

        try await sut.resumeTransfer(transfer)

        #expect(repo.resumedTransfers.map(\.tag) == [2])
        #expect(repo.pausedTransfers.isEmpty)
    }

    @Test("Pause errors are rethrown")
    func pauseTransferRethrowsRepositoryError() async {
        let repo = MockTransferControlRepository.newRepo
        repo.pauseError = TestError.pause
        let (sut, _) = Self.makeSUT(repo: repo)

        await #expect(throws: TestError.pause) {
            try await sut.pauseTransfer(TransferEntity(tag: 3))
        }
        #expect(repo.pausedTransfers.map(\.tag) == [3])
        #expect(repo.resumedTransfers.isEmpty)
    }

    @Test("Resume errors are rethrown")
    func resumeTransferRethrowsRepositoryError() async {
        let repo = MockTransferControlRepository.newRepo
        repo.resumeError = TestError.resume
        let (sut, _) = Self.makeSUT(repo: repo)

        await #expect(throws: TestError.resume) {
            try await sut.resumeTransfer(TransferEntity(tag: 4))
        }
        #expect(repo.resumedTransfers.map(\.tag) == [4])
        #expect(repo.pausedTransfers.isEmpty)
    }

    @Test("Retrying a transfer forwards the transfer to the repository")
    func retryTransfer() async throws {
        let (sut, repo) = Self.makeSUT()
        let transfer = TransferEntity(tag: 5)

        try await sut.retryTransfer(transfer)

        #expect(repo.retriedTransfers.map(\.tag) == [5])
        #expect(repo.pausedTransfers.isEmpty)
        #expect(repo.resumedTransfers.isEmpty)
    }

    @Test("Retry errors are rethrown")
    func retryTransferRethrowsRepositoryError() async {
        let repo = MockTransferControlRepository.newRepo
        repo.retryError = TestError.retry
        let (sut, _) = Self.makeSUT(repo: repo)

        await #expect(throws: TestError.retry) {
            try await sut.retryTransfer(TransferEntity(tag: 6))
        }
        #expect(repo.retriedTransfers.map(\.tag) == [6])
        #expect(repo.pausedTransfers.isEmpty)
        #expect(repo.resumedTransfers.isEmpty)
    }
}
