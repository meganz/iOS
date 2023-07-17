import MEGADomain
import MEGASdk

public extension TransferStateEntity {
    init?(transferState: MEGATransferState) {
        self.init(rawValue: transferState.rawValue)
    }
}
