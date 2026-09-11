import MEGADomain
import MEGASdk

public extension TransferQuotaStateEntity {
    init?(transferQuotaState: MEGATransferQuotaState) {
        switch transferQuotaState {
        case .green: self = .green
        case .orange: self = .orange
        case .red: self = .red
        case .unknown: return nil
        @unknown default: return nil
        }
    }
}
