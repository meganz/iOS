@testable import MEGA
import Testing

struct MEGAPurchaseDelegatesTestSuite {

    @Suite("Purchase delegates")
    struct PurchaseDelegateTests {
        @Test("Adding a delegate registers it")
        func addDelegate_registersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockPurchaseDelegate()

            sut.addPurchaseDelegate(delegate)

            #expect(sut.purchaseDelegates.count == 1)
            #expect(sut.purchaseDelegates.contains { ($0 as AnyObject) === delegate })
        }

        @Test("Adding the same delegate twice does not create a duplicate")
        func addDelegate_whenAlreadyAdded_doesNotDuplicate() {
            let sut = MEGAPurchase()
            let delegate = MockPurchaseDelegate()

            sut.addPurchaseDelegate(delegate)
            sut.addPurchaseDelegate(delegate)

            #expect(sut.purchaseDelegates.count == 1)
        }

        @Test("Adding distinct delegates registers each one")
        func addDelegate_withMultipleDelegates_registersEach() {
            let sut = MEGAPurchase()
            let firstDelegate = MockPurchaseDelegate()
            let secondDelegate = MockPurchaseDelegate()

            sut.addPurchaseDelegate(firstDelegate)
            sut.addPurchaseDelegate(secondDelegate)

            #expect(sut.purchaseDelegates.count == 2)
        }

        @Test("Removing a delegate unregisters it")
        func removeDelegate_unregistersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockPurchaseDelegate()
            sut.addPurchaseDelegate(delegate)

            sut.removePurchaseDelegate(delegate)

            #expect(sut.purchaseDelegates.isEmpty)
        }

        @Test("Removing one delegate keeps the others")
        func removeDelegate_withMultipleDelegates_removesOnlyMatching() {
            let sut = MEGAPurchase()
            let delegateToKeep = MockPurchaseDelegate()
            let delegateToRemove = MockPurchaseDelegate()
            sut.addPurchaseDelegate(delegateToKeep)
            sut.addPurchaseDelegate(delegateToRemove)

            sut.removePurchaseDelegate(delegateToRemove)

            #expect(sut.purchaseDelegates.count == 1)
            #expect(sut.purchaseDelegates.contains { ($0 as AnyObject) === delegateToKeep })
        }
    }

    @Suite("Restore delegates")
    struct RestoreDelegateTests {
        @Test("Adding a delegate registers it")
        func addDelegate_registersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockRestoreDelegate()

            sut.addRestoreDelegate(delegate)

            #expect(sut.restoreDelegates.count == 1)
            #expect(sut.restoreDelegates.contains { ($0 as AnyObject) === delegate })
        }

        @Test("Adding the same delegate twice does not create a duplicate")
        func addDelegate_whenAlreadyAdded_doesNotDuplicate() {
            let sut = MEGAPurchase()
            let delegate = MockRestoreDelegate()

            sut.addRestoreDelegate(delegate)
            sut.addRestoreDelegate(delegate)

            #expect(sut.restoreDelegates.count == 1)
        }

        @Test("Removing a delegate unregisters it")
        func removeDelegate_unregistersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockRestoreDelegate()
            sut.addRestoreDelegate(delegate)

            sut.removeRestoreDelegate(delegate)

            #expect(sut.restoreDelegates.isEmpty)
        }
    }

    @Suite("Pricing delegates")
    struct PricingDelegateTests {
        @Test("Adding a delegate registers it")
        func addDelegate_registersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockPricingDelegate()

            sut.addPricingsDelegate(delegate)

            #expect(sut.pricingDelegates.count == 1)
            #expect(sut.pricingDelegates.contains { ($0 as AnyObject) === delegate })
        }

        @Test("Adding the same delegate twice does not create a duplicate")
        func addDelegate_whenAlreadyAdded_doesNotDuplicate() {
            let sut = MEGAPurchase()
            let delegate = MockPricingDelegate()

            sut.addPricingsDelegate(delegate)
            sut.addPricingsDelegate(delegate)

            #expect(sut.pricingDelegates.count == 1)
        }

        @Test("Removing a delegate unregisters it")
        func removeDelegate_unregistersDelegate() {
            let sut = MEGAPurchase()
            let delegate = MockPricingDelegate()
            sut.addPricingsDelegate(delegate)

            sut.removePricingsDelegate(delegate)

            #expect(sut.pricingDelegates.isEmpty)
        }
    }
}

// MARK: - Test doubles

private final class MockPurchaseDelegate: NSObject, MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase) {}
}

private final class MockRestoreDelegate: NSObject, MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase) {}
}

private final class MockPricingDelegate: NSObject, MEGAPurchasePricingDelegate {
    func pricingsFailed() {}

    func pricingsReady() {}
}
