public struct AccountSubscriptionEntity: Sendable {
    public let id: String?
    public let status: SubscriptionStatusEntity
    public let cycle: String?
    public let paymentMethod: String?
    public let paymentMethodId: Int32
    public let renewTime: Int64
    public let accountType: AccountTypeEntity
    public let features: [String]?

    public init(
       id: String?,
       status: SubscriptionStatusEntity,
       cycle: String?,
       paymentMethod: String?,
       paymentMethodId: Int32,
       renewTime: Int64,
       accountType: AccountTypeEntity,
       features: [String]?
   ) {
       self.id = id
       self.status = status
       self.cycle = cycle
       self.paymentMethod = paymentMethod
       self.paymentMethodId = paymentMethodId
       self.renewTime = renewTime
       self.accountType = accountType
       self.features = features
   }
}
