import MEGADomain
import Transfer

final class MockClearTransfersRepository: ClearTransfersRepositoryProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfers_calledTimes = 0
    private(set) var clearFailedTransfers_calledTimes = 0
    private(set) var clearTransfer_tags: [Int] = []
    private(set) var clearTransfers_tagSets: [Set<Int>] = []
    var clearCompletedTransfersTags: Set<Int> = []
    var clearFailedTransfersTags: Set<Int> = []
    var clearTransferTags: Set<Int> = []

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

    func clearTransfer(tag: Int) -> Set<Int> {
        clearTransfer_tags.append(tag)
        return clearTransferTags
    }

    func clearTransfers(tags: Set<Int>) -> Set<Int> {
        clearTransfers_tagSets.append(tags)
        return tags
    }
}
