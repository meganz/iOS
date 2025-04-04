import MEGADomain
import MEGASdk

public extension TransferEntity {
    func toMEGATransfer(in sdk: MEGASdk) -> MEGATransfer? {
        sdk.transfer(byTag: tag)
    }
}
