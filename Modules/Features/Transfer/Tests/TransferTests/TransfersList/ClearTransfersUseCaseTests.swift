import Foundation
import Testing
import Transfer

@Suite("ClearTransfersUseCase forwards clear requests to its repository.")
struct ClearTransfersUseCaseTests {
    private static func makeSUT() -> (
        sut: ClearTransfersUseCase,
        repo: MockClearTransfersRepository,
        finishDateProvider: SpyTransferFinishDateProvider
    ) {
        let repo = MockClearTransfersRepository.newRepo
        let finishDateProvider = SpyTransferFinishDateProvider()
        return (
            ClearTransfersUseCase(repo: repo, finishDateProvider: finishDateProvider),
            repo,
            finishDateProvider
        )
    }

    @Test("Clearing completed transfers only touches the completed list")
    func clearsCompletedTransfers() {
        let (sut, repo, finishDateProvider) = Self.makeSUT()
        repo.clearCompletedTransfersTags = [1, 2]

        sut.clearCompletedTransfers()

        #expect(repo.clearCompletedTransfers_calledTimes == 1)
        #expect(repo.clearFailedTransfers_calledTimes == 0)
        #expect(finishDateProvider.removedTags == [1, 2])
    }

    @Test("Clearing failed transfers only touches the failed list")
    func clearsFailedTransfers() {
        let (sut, repo, finishDateProvider) = Self.makeSUT()
        repo.clearFailedTransfersTags = [3, 4]

        sut.clearFailedTransfers()

        #expect(repo.clearFailedTransfers_calledTimes == 1)
        #expect(repo.clearCompletedTransfers_calledTimes == 0)
        #expect(finishDateProvider.removedTags == [3, 4])
    }

    @Test("Clearing a single transfer removes only that tag's finish date")
    func clearsSingleTransfer() {
        let (sut, repo, finishDateProvider) = Self.makeSUT()
        repo.clearTransferTags = [9]

        sut.clearTransfer(tag: 9)

        #expect(repo.clearTransfer_tags == [9])
        #expect(repo.clearCompletedTransfers_calledTimes == 0)
        #expect(repo.clearFailedTransfers_calledTimes == 0)
        #expect(finishDateProvider.removedTags == [9])
    }
}

private final class SpyTransferFinishDateProvider: TransferFinishDateProviding, @unchecked Sendable {
    private(set) var removedTags: Set<Int> = []

    func finishDate(forTag tag: Int) -> Date? {
        nil
    }

    func recordIfAbsent(tag: Int, date: Date) -> Date {
        date
    }

    func removeDates(forTags tags: Set<Int>) {
        removedTags = tags
    }
}
