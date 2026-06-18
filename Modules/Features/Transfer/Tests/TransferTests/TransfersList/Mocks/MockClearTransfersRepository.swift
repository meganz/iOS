import MEGADomain
import Transfer

final class MockClearTransfersRepository: ClearTransfersRepositoryProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfers_calledTimes = 0
    private(set) var clearFailedTransfers_calledTimes = 0
    var clearCompletedTransfersTags: Set<Int> = []
    var clearFailedTransfersTags: Set<Int> = []

    static var newRepo: MockClearTransfersRepository {
        MockClearTransfersRepository()
    }

    init() {}

    func clearCompletedTransfers() -> Set<Int> {
        clearCompletedTransfers_calledTimes += 1
        return clearCompletedTransfersTags
    }

    func clearFailedTransfers() -> Set<Int> {
        clearFailedTransfers_calledTimes += 1
        return clearFailedTransfersTags
    }
}
