import MEGADomain

// MARK: - SKProduct
extension SKProduct {
    func toAccountPlanEntity(product: SKProduct,
                             storage: Int,
                             transfer: Int) -> AccountPlanEntity {
        return AccountPlanEntity(product: product,
                                 storageLimit: storage,
                                 transferLimit: transfer)
    }
}

// MARK: - AccountPlanTerm
fileprivate extension AccountPlanTermEntity {
    init(productIdentifier identifier: String) {
        switch identifier {
        case let id where id.contains("oneYear"): self = .yearly
        case let id where id.contains("oneMonth"): self = .monthly
        default: self = .none
        }
    }
}

// MARK: - AccountPlanEntity
fileprivate extension AccountPlanEntity {
    init(product: SKProduct,
         storageLimit: Int,
         transferLimit: Int) {
        
        self.init()

        let productIdentifier = product.productIdentifier
        term = AccountPlanTermEntity(productIdentifier: productIdentifier)
        
        let planType = planType(productIdentifier: productIdentifier)
        name = MEGAAccountDetails.string(for: planType)
        type = planType.toAccountTypeEntity()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        currency = numberFormatter.currencyCode
        formattedPrice = numberFormatter.string(for: product.price) ?? ""
        currency = numberFormatter.currencyCode
        price = product.price.doubleValue
        
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
