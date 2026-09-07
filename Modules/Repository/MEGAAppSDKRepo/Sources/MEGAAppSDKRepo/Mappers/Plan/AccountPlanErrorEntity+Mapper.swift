import MEGADomain
import StoreKit

// Custom error to represent the case of promotional offer resolution error
extension AccountPlanErrorEntity {

    // Here we use 2 values `-1` and `promotionalOfferUnavailableError`
    // to identify the `promotional offer unavailable`.
    public static let promotionalOfferUnavailableError = AccountPlanErrorEntity(errorCode: -1, errorMessage: "promotionalOfferUnavailableError")
}

extension AccountPlanErrorEntity {
    public func toPurchaseErrorStatus() -> AccountPlanPurchaseErrorEntity {
        // Here we use equatable check (which is error code and message)
        // because the error code alone can be accidental match with other system errors.
        if self == Self.promotionalOfferUnavailableError {
            return .promotionalOfferUnavailable
        }

        let skError = SKError.Code(rawValue: errorCode)
        switch skError {
        case .paymentCancelled: return .paymentCancelled
        case .paymentInvalid: return .paymentInvalid
        case .paymentNotAllowed: return .paymentNotAllowed
        default: return .unknown
        }
    }
}
