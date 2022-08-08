import MEGADomain

extension TransferStageEntity {
    init?(transferStage: MEGATransferStage) {
        self.init(rawValue: transferStage.rawValue)
    }
}
