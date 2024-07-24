public struct PlanEntity: Sendable {
    public let productIdentifier: String
    public var type: AccountTypeEntity
    public var name: String
    public var currency: String
    public var subscriptionCycle: SubscriptionCycleEntity
    public var storage: String
    public var transfer: String
    public var price: Double
    public var formattedPrice: String
    
    public init(productIdentifier: String = "",
                type: AccountTypeEntity = .free,
                name: String = "",
                currency: String = "",
                subscriptionCycle: SubscriptionCycleEntity = .none,
                storage: String = "",
                transfer: String = "",
                price: Double = 0,
                formattedPrice: String = "") {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.currency = currency
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.price = price
        self.formattedPrice = formattedPrice
    }
}

extension PlanEntity: Equatable {
    public static func == (lhs: PlanEntity, rhs: PlanEntity) -> Bool {
        lhs.type == rhs.type && lhs.subscriptionCycle == rhs.subscriptionCycle
    }
}

extension PlanEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(subscriptionCycle)
    }
}
