import MEGADomain

extension MEGAError {
    func toTransferErrorEntity() -> TransferErrorEntity? {
        switch type {
        case .apiOk:
            return nil
        case .apiEOverQuota:
            return .overquota
        default:
            return .generic
        }
    }
}
