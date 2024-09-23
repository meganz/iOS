public enum AccountPlanPurchaseErrorEntity {
    case paymentCancelled, paymentInvalid, paymentNotAllowed, unknown
}

public struct AccountPlanErrorEntity: Error {
    public let errorCode: Int
    public let errorMessage: String?
    
    public init(errorCode: Int, errorMessage: String?) {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
}

extension AccountPlanErrorEntity: Equatable {
    public static func == (lhs: AccountPlanErrorEntity, rhs: AccountPlanErrorEntity) -> Bool {
        lhs.errorCode == rhs.errorCode && lhs.errorMessage == rhs.errorMessage
    }
}
