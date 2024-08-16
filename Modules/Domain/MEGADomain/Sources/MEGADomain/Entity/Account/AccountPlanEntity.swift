public struct AccountPlanEntity: Sendable {
    public let isProPlan: Bool
    public let accountType: AccountTypeEntity
    public let expirationTime: Int64
    public let features: [String]?
    public let type: Int32
    public let subscriptionId: String?
    
    public init(
       isProPlan: Bool,
       accountType: AccountTypeEntity,
       expirationTime: Int64,
       features: [String]?,
       type: Int32,
       subscriptionId: String?
   ) {
       self.isProPlan = isProPlan
       self.accountType = accountType
       self.expirationTime = expirationTime
       self.features = features
       self.type = type
       self.subscriptionId = subscriptionId
   }
}

extension AccountPlanEntity: Equatable {
    public static func == (lhs: AccountPlanEntity, rhs: AccountPlanEntity) -> Bool {
        return lhs.accountType == rhs.accountType && 
               lhs.subscriptionId == lhs.subscriptionId
    }
}
