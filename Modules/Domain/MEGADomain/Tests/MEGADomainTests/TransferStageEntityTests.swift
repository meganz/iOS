import MEGADomain
import Testing

/// Covers the order `TransferStageEntity` is compared in.
///
/// A batch upload asks whether an item has reached its transferring stage by comparing the stage
/// it last reported against `.transferringFiles`, so the order the stages sort in is what decides
/// whether the batch calls itself away -- not a detail of the enum.
@Suite("TransferStageEntity Tests")
struct TransferStageEntityTests {

    @Test("The stages sort in the order a transfer passes through them")
    func stagesSortInTheOrderTheyHappen() {
        #expect(
            [TransferStageEntity.transferringFiles, .none, .createTree, .scan].sorted()
                == [.none, .scan, .createTree, .transferringFiles]
        )
    }

    @Test(
        "Only the transferring stage counts as having reached it",
        arguments: [
            (TransferStageEntity.none, false),
            (.scan, false),
            (.createTree, false),
            (.transferringFiles, true)
        ]
    )
    func onlyTheTransferringStageCountsAsReachingIt(stage: TransferStageEntity, hasReachedIt: Bool) {
        #expect((stage >= .transferringFiles) == hasReachedIt)
    }
}
