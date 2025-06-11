import MEGAL10n

@MainActor
struct SubscriptionPurchaseFreePlanViewModel {
    private let maxStorageSize: Int64
    
    var storageTile: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard
            .Feature.storage(String.memoryStyleString(fromByteCount: maxStorageSize)
                .formattedByteCountString())
    }
    
    init(maxStorageSize: Int64) {
        self.maxStorageSize = maxStorageSize
    }
}
