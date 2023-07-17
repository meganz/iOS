import MEGADomain
import MEGASdk

public extension TransferTypeEntity {
    init?(transferType: MEGATransferType) {
        self.init(rawValue: transferType.rawValue)
    }
}
