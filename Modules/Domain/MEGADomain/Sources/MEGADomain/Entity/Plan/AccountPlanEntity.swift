
public struct AccountPlanEntity: Sendable {
    public let productIdentifier: String
    public var type: AccountTypeEntity
    public var name: String
    public var currency: String
    public var term: AccountPlanTermEntity
    public var storage: String
    public var transfer: String
    public var price: Double
    public var formattedPrice: String
    
    public init(productIdentifier: String = "",
                type: AccountTypeEntity = .free,
                name: String = "",
                currency: String = "",
                term: AccountPlanTermEntity = .none,
                storage: String = "",
                transfer: String = "",
                price: Double = 0,
                formattedPrice: String = "") {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.currency = currency
        self.term = term
        self.storage = storage
        self.transfer = transfer
        self.price = price
        self.formattedPrice = formattedPrice
    }
}

extension AccountPlanEntity: Equatable {
    public static func == (lhs: AccountPlanEntity, rhs: AccountPlanEntity) -> Bool {
        lhs.type == rhs.type && lhs.term == rhs.term
    }
}

extension AccountPlanEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(term)
    }
}
