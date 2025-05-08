import MEGADomain
import MEGASdk
import StoreKit

// MARK: - SKProduct
extension SKProduct {
    public func toPlanEntity(
        storage: Int = 0,
        transfer: Int = 0,
        price: Double? = nil,
        currencyCode: String? = nil
    ) -> PlanEntity {
        PlanEntity(
            product: self,
            storageLimit: storage,
            transferLimit: transfer,
            price: price,
            currencyCode: currencyCode
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
            storage: storageGB(atProductIndex: index).toGBString(),
            transfer: transferGB(atProductIndex: index).toGBString()
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
        price: Double? = nil,
        currencyCode: String? = nil
    ) {
        self.init(productIdentifier: product.productIdentifier)
        
        let productIdentifier = product.productIdentifier
        subscriptionCycle = SubscriptionCycleEntity(productIdentifier: productIdentifier)
        
        let planType = planType(productIdentifier: productIdentifier)
        name = MEGAAccountDetails.string(for: planType) ?? ""
        type = planType.toAccountTypeEntity()

        let actualPrice = price ?? product.price.doubleValue

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        if let currencyCode {
            numberFormatter.currencyCode = currencyCode
        } else {
            numberFormatter.locale = product.priceLocale
        }

        formattedPrice = numberFormatter.string(for: actualPrice) ?? ""
        currency = numberFormatter.currencyCode
        self.price = actualPrice

        formattedMonthlyPriceForYearlyPlan = subscriptionCycle == .yearly
        ? numberFormatter.string(for: Int(ceil(self.price / 12.0)))
        : nil

        storage = displayStringForGBValue(gbValue: storageLimit)
        transfer = displayStringForGBValue(gbValue: transferLimit)
    }

    private func planType(productIdentifier: String) -> MEGAAccountType {
        if productIdentifier.contains("pro1") {
            return .proI
        } else if productIdentifier.contains("pro2") {
            return .proII
        } else if productIdentifier.contains("pro3") {
            return .proIII
        } else {
            return .lite
        }
    }
    
    private func displayStringForGBValue(gbValue: Int) -> String {
        // 1 GB = 1024 * 1024 * 1024 Bytes
        let valueIntBytes: Int64 = Int64(gbValue * 1024 * 1024 * 1024)
        return ByteCountFormatter.string(fromByteCount: valueIntBytes, countStyle: .binary)
    }
}
