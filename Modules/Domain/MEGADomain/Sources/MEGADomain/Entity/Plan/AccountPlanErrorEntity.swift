public enum AccountPlanPurchaseErrorEntity: Sendable {
    case paymentCancelled, paymentInvalid, paymentNotAllowed, unknown
    // Error when attempting to buy a promotional offer (driven by `mo.ios`) but the offer data cannot be resolved.
    case promotionalOfferUnavailable
}

public struct AccountPlanErrorEntity: Error, Equatable {
    public let errorCode: Int
    public let errorMessage: String?
    
    public init(errorCode: Int, errorMessage: String?) {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}
