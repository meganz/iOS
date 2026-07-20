public struct RecommendedUpgradePlanEntity: Sendable, Equatable {
    public let name: String
    /// Display string for storage, e.g. "200 GB".
    public let storage: String
    /// Storage allowance in gigabytes
    public let storageLimit: Int
    /// Display string for transfer, e.g. "2 TB".
    public let transfer: String
    /// Transfer allowance in gigabytes
    public let transferLimit: Int
    /// Campaign label for the ribbon, when the plan carries a promoted offer.
    public let mobileOfferLabel: String?
    /// The resolved price; presentation maps this to its own `PlanPrice`.
    public let price: SubscriptionPlanPrice

    public init(
        name: String,
        storage: String,
        storageLimit: Int,
        transfer: String,
        transferLimit: Int,
        mobileOfferLabel: String?,
        price: SubscriptionPlanPrice
    ) {
        self.name = name
        self.storage = storage
        self.storageLimit = storageLimit
        self.transfer = transfer
        self.transferLimit = transferLimit
        self.mobileOfferLabel = mobileOfferLabel
        self.price = price
    }
}
