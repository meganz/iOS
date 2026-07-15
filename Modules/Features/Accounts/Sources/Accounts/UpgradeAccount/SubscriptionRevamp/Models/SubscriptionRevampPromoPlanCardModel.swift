struct SubscriptionRevampPromoPlanCardModel: Equatable {
    let ribbonText: String
    let title: String
    let originalPrice: String
    let discountedPrice: String
    let priceDescription: String
    let storage: String
    let transfer: String
    let buttonTitle: String

    init(
        ribbonText: String,
        title: String,
        originalPrice: String,
        discountedPrice: String,
        priceDescription: String,
        storage: String,
        transfer: String,
        buttonTitle: String
    ) {
        self.ribbonText = ribbonText
        self.title = title
        self.originalPrice = originalPrice
        self.discountedPrice = discountedPrice
        self.priceDescription = priceDescription
        self.storage = storage
        self.transfer = transfer
        self.buttonTitle = buttonTitle
    }
}
