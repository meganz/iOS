import MEGAUIComponent

struct SubscriptionPlanCardModel: Identifiable, Equatable {
    let productIdentifier: String
    let title: String
    let price: PlanPrice
    let storage: String
    let transfer: String
    let ribbonText: String?
    let isPrimaryAction: Bool
    let externalPurchaseTitle: String?

    var id: String { productIdentifier }

    var hasOffer: Bool {
        switch price {
        case .discountMonthly, .discountYearly: true
        case .monthly, .yearly: false
        }
    }

    init(
        productIdentifier: String,
        title: String,
        price: PlanPrice,
        storage: String,
        transfer: String,
        ribbonText: String? = nil,
        isPrimaryAction: Bool = false,
        externalPurchaseTitle: String? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.title = title
        self.price = price
        self.storage = storage
        self.transfer = transfer
        self.ribbonText = ribbonText
        self.isPrimaryAction = isPrimaryAction
        self.externalPurchaseTitle = externalPurchaseTitle
    }
}
