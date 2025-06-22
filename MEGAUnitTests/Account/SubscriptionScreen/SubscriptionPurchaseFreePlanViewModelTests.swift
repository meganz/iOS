@testable import MEGA
import MEGAL10n
import Testing

struct SubscriptionPurchaseFreePlanViewModelTests {
    
    @Test(arguments: [
        (true, Strings.Localizable.SubscriptionPurchase.FreePlanCard.Title.upgrade),
        (false, Strings.Localizable.SubscriptionPurchase.FreePlanCard.title)]
    )
    @MainActor
    func cardTitle(isExistingFreeAccount: Bool, expectedTitle: String) {
        let sut = Self.makeSUT(isExistingFreeAccount: isExistingFreeAccount)
        
        #expect(sut.cardTitle == expectedTitle)
    }
    
    @Test(arguments: [true, false])
    @MainActor
    func showDescription(isExistingFreeAccount: Bool) {
        let sut = Self.makeSUT(isExistingFreeAccount: isExistingFreeAccount)
        
        #expect(sut.showDescription == !isExistingFreeAccount)
    }
    
    @Test(arguments: [0, 21_474_836_480])
    @MainActor
    func storageTitle(storageSize: Int64) {
        let sut = Self.makeSUT(maxStorageSize: storageSize)
        
        let storageSize = String.memoryStyleString(fromByteCount: storageSize)
            .formattedByteCountString()
        #expect(sut.storageTile == Strings.Localizable.SubscriptionPurchase.FreePlanCard
            .Feature.storage(storageSize))
    }
    
    @Test(arguments: [
        (true, Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.Title.upgrade),
        (false, Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.title)]
    )
    @MainActor
    func primaryButtonTitle(isExistingFreeAccount: Bool, expectedTitle: String) {
        let sut = Self.makeSUT(isExistingFreeAccount: isExistingFreeAccount)
        
        #expect(sut.primaryButtonTitle == expectedTitle)
    }
    
    @MainActor
    private static func makeSUT(
        isExistingFreeAccount: Bool = false,
        maxStorageSize: Int64 = 0
    ) -> SubscriptionPurchaseFreePlanViewModel {
        .init(isExistingFreeAccount: isExistingFreeAccount,
              maxStorageSize: maxStorageSize)
    }
}
