import MEGAL10n
import MEGAUIComponent

struct SubscriptionPlanCardModel: Identifiable, Equatable {
    enum Ribbon: Equatable {
        case offer(String)
        case recommended

        var text: String {
            switch self {
            case .offer(let text): text
            case .recommended: Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended
            }
        }
    }

    let productIdentifier: String
    let title: String
    let price: PlanPrice
    let storage: String
    let transfer: String
    let ribbon: Ribbon?
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
        ribbon: Ribbon? = nil,
        isPrimaryAction: Bool = false,
        externalPurchaseTitle: String? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.title = title
        self.price = price
        self.storage = storage
        self.transfer = transfer
        self.ribbon = ribbon
        self.isPrimaryAction = isPrimaryAction
        self.externalPurchaseTitle = externalPurchaseTitle
    }
}
