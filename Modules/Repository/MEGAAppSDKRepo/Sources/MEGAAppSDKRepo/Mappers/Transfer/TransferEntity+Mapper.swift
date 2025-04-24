import MEGADomain
import MEGASdk

public extension TransferEntity {
    func toMEGATransfer(in sdk: MEGASdk) -> MEGATransfer? {
        sdk.transfer(byTag: tag)
    }
}

public extension Array where Element == TransferEntity {
    func toMEGATransfers(in sdk: MEGASdk) -> [MEGATransfer] {
        compactMap { $0.toMEGATransfer(in: sdk) }
    }
}
