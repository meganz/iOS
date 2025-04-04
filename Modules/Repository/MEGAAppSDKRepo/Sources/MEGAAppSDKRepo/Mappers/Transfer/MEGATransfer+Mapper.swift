import MEGADomain
import MEGASdk

public extension MEGATransfer {
    func toTransferEntity() -> TransferEntity {
        TransferEntity(transfer: self)
    }
}

extension MEGATransfer: @retroactive @unchecked Sendable {}
