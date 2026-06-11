import Testing
import Transfer

@Suite("ClearTransfersUseCase forwards clear requests to its repository.")
struct ClearTransfersUseCaseTests {
    private static func makeSUT() -> (sut: ClearTransfersUseCase, repo: MockClearTransfersRepository) {
        let repo = MockClearTransfersRepository.newRepo
        return (ClearTransfersUseCase(repo: repo), repo)
    }

    @Test("Clearing completed transfers only touches the completed list")
    func clearsCompletedTransfers() {
        let (sut, repo) = Self.makeSUT()

        sut.clearCompletedTransfers()

        #expect(repo.clearCompletedTransfers_calledTimes == 1)
        #expect(repo.clearFailedTransfers_calledTimes == 0)
    }

    @Test("Clearing failed transfers only touches the failed list")
    func clearsFailedTransfers() {
        let (sut, repo) = Self.makeSUT()

        sut.clearFailedTransfers()

        #expect(repo.clearFailedTransfers_calledTimes == 1)
        #expect(repo.clearCompletedTransfers_calledTimes == 0)
    }
}
