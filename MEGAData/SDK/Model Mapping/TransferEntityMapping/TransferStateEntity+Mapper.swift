import MEGADomain

extension TransferStateEntity {
    init?(transferState: MEGATransferState) {
        self.init(rawValue: transferState.rawValue)
    }
}
