import MEGADomain
import StoreKit

extension AccountPlanErrorEntity {
    public func toPurchaseErrorStatus() -> AccountPlanPurchaseErrorEntity {
        let skError = SKError.Code(rawValue: errorCode)
        switch skError {
        case .paymentCancelled: return .paymentCancelled
        case .paymentInvalid: return .paymentInvalid
        case .paymentNotAllowed: return .paymentNotAllowed
        default: return .unknown
        }
    }
}
