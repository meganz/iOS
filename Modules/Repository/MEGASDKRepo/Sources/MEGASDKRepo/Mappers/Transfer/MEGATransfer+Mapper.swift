import MEGADomain
import MEGASdk

public extension MEGATransfer {
    func toTransferEntity() -> TransferEntity {
        TransferEntity(transfer: self)
    }
}
