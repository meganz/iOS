import MEGADomain
import MEGASdk

public extension TransferStageEntity {
    init?(transferStage: MEGATransferStage) {
        self.init(rawValue: transferStage.rawValue)
    }
}
