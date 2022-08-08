import MEGADomain

extension TransferTypeEntity {
    init?(transferType: MEGATransferType) {
        self.init(rawValue: transferType.rawValue)
    }
}
