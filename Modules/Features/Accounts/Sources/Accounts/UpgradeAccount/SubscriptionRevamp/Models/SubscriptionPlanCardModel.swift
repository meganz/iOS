struct SubscriptionPlanCardModel: Identifiable, Equatable {
    enum Price: Equatable {
        case monthly(price: String)
        case yearly(price: String, billing: String)
        case discount(originalPrice: String, discountedPrice: String, description: String)
    }

    let title: String
    let price: Price
    let storage: String
    let transfer: String
    let ribbonText: String?
    let isPrimaryAction: Bool

    var id: String { title }

    init(
        title: String,
        price: Price,
        storage: String,
        transfer: String,
        ribbonText: String? = nil,
        isPrimaryAction: Bool = false
    ) {
        self.title = title
        self.price = price
        self.storage = storage
        self.transfer = transfer
        self.ribbonText = ribbonText
        self.isPrimaryAction = isPrimaryAction
    }
}
