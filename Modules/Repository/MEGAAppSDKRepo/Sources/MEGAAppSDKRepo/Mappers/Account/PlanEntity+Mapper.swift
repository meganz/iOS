import MEGADomain
import MEGASdk
import StoreKit

// MARK: - SKProduct
extension SKProduct {
    public func toPlanEntity(
        planType: MEGAAccountType,
        storage: Int = 0,
        transfer: Int = 0,
        apiPrice: Decimal? = nil,
        apiCurrencyCode: String? = nil,
        useAPIPrice: Bool = false,
        mobileOffer: MobileOfferEntity? = nil,
    ) -> PlanEntity {
        PlanEntity(
            product: self,
            storageLimit: storage,
            transferLimit: transfer,
            apiPrice: apiPrice,
            apiCurrencyCode: apiCurrencyCode,
            useAPIPrice: useAPIPrice,
            planType: planType,
            mobileOffer: mobileOffer
        )
    }
}

// MARK: - MEGAPricing
extension MEGAPricing {
    public func toPlanEntity(index: Int) -> PlanEntity? {
        guard let id = iOSID(atProductIndex: index) else { return nil }
        return PlanEntity(
            productIdentifier: id,
            type: proLevel(atProductIndex: index).toAccountTypeEntity(),
            subscriptionCycle: SubscriptionCycleEntity(productIdentifier: id),
            storageLimit: storageGB(atProductIndex: index),
            transferLimit: transferGB(atProductIndex: index)
        )
    }
}

// MARK: - SubscriptionCycleEntity
fileprivate extension SubscriptionCycleEntity {
    init(productIdentifier identifier: String) {
        switch identifier {
        case let id where id.contains("oneYear"): self = .yearly
        case let id where id.contains("oneMonth"): self = .monthly
        default: self = .none
        }
    }
}

// MARK: - PlanEntity
fileprivate extension PlanEntity {
    init(
        product: SKProduct,
        storageLimit: Int,
        transferLimit: Int,
        apiPrice: Decimal?,
        apiCurrencyCode: String?,
        useAPIPrice: Bool,
        planType: MEGAAccountType,
        mobileOffer: MobileOfferEntity? = nil
    ) {
        let productIdentifier = product.productIdentifier
        self.init(productIdentifier: productIdentifier)
        self.mobileOffer = mobileOffer
        subscriptionCycle = SubscriptionCycleEntity(productIdentifier: productIdentifier)

        name = MEGAAccountDetails.string(for: planType) ?? ""
        type = planType.toAccountTypeEntity()

        appStorePrice = PlanPriceEntity(
            price: product.price.decimalValue,
            formattedPrice: {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = product.priceLocale
                return numberFormatter.string(for: product.price) ?? ""
            }(),
            currency: product.priceLocale.currency?.identifier ?? ""
        )

        self.storageLimit = storageLimit
        self.transferLimit = transferLimit
        storage = storageLimit.toGBString()
        transfer = transferLimit.toGBString()

        guard useAPIPrice, let apiPrice, apiPrice > 0, let apiCurrencyCode else { return }

        self.apiPrice = PlanPriceEntity(
            price: apiPrice,
            formattedPrice: {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.currencyCode = apiCurrencyCode
                return numberFormatter.string(for: apiPrice) ?? ""
            }(),
            currency: apiCurrencyCode
        )
    }
}
