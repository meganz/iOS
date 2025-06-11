@testable import MEGA
import MEGAL10n
import Testing

struct SubscriptionPurchaseFreePlanViewModelTests {
    
    @Test(arguments: [0, 21_474_836_480])
    @MainActor
    func storageTitle(storageSize: Int64) {
        let sut = SubscriptionPurchaseFreePlanViewModel(maxStorageSize: storageSize)
        
        let storageSize = String.memoryStyleString(fromByteCount: storageSize)
            .formattedByteCountString()
        #expect(sut.storageTile == Strings.Localizable.SubscriptionPurchase.FreePlanCard
            .Feature.storage(storageSize))
    }
}
