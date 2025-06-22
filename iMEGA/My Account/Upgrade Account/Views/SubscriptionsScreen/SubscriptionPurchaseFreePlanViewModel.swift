import MEGAL10n

@MainActor
struct SubscriptionPurchaseFreePlanViewModel {
    private let isExistingFreeAccount: Bool
    private let maxStorageSize: Int64
    
    var cardTitle: String {
        if isExistingFreeAccount {
            Strings.Localizable.SubscriptionPurchase.FreePlanCard.Title.upgrade
        } else {
            Strings.Localizable.SubscriptionPurchase.FreePlanCard.title
        }
    }
    
    var showDescription: Bool {
        !isExistingFreeAccount
    }
    
    var storageTile: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard
            .Feature.storage(String.memoryStyleString(fromByteCount: maxStorageSize)
                .formattedByteCountString())
    }
    
    var primaryButtonTitle: String {
        if isExistingFreeAccount {
            Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.Title.upgrade
        } else {
            Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.title
        }
    }
    
    init(isExistingFreeAccount: Bool, maxStorageSize: Int64) {
        self.isExistingFreeAccount = isExistingFreeAccount
        self.maxStorageSize = maxStorageSize
    }
}
