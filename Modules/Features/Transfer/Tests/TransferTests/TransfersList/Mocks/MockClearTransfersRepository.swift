import MEGADomain
import Transfer

final class MockClearTransfersRepository: ClearTransfersRepositoryProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfers_calledTimes = 0
    private(set) var clearFailedTransfers_calledTimes = 0

    static var newRepo: MockClearTransfersRepository {
        MockClearTransfersRepository()
    }

    init() {}

    func clearCompletedTransfers() {
        clearCompletedTransfers_calledTimes += 1
    }

    func clearFailedTransfers() {
        clearFailedTransfers_calledTimes += 1
    }
}
