import MEGADomain
import MEGASdk

public extension MEGAError {
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
    
    /// The full error type of a transfer error, or `nil` when there is no error.
    func toTransferErrorTypeEntity() -> ErrorTypeEntity? {
        let errorType = type.toErrorTypeEntity()
        return errorType == .ok ? nil : errorType
    }
    
    /// The SDK's English description of a transfer error, which is also its localization
    /// key — the text the legacy Transfers screen showed. `nil` when there is no error.
    func toTransferErrorString(transferType: MEGATransferType) -> String? {
        guard type != .apiOk else { return nil }
        return MEGAError.errorStringWithErrorCode(
            type.rawValue,
            context: transferType == .upload ? .upload : .download
        )
    }
}
