import Combine
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Plans
    func testAccountPlanProducts_monthly() async {
        let identifiers = ["pro1.oneMonth", "pro2.oneMonth", "pro3.oneMonth", "lite.oneMonth"]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .monthly),
                              PlanEntity(type: .proII, subscriptionCycle: .monthly),
                              PlanEntity(type: .proIII, subscriptionCycle: .monthly),
                              PlanEntity(type: .lite, subscriptionCycle: .monthly)]

        let sut = makeSUT(purchase: makePurchase(storeProductIdentifiers: identifiers, pricingProductIdentifiers: identifiers))
        let plans = await sut.accountPlanProducts(useAPIPrice: false)
        XCTAssertEqual(plans, expectedResult)
    }

    func testAccountPlanProducts_yearly() async {
        let identifiers = ["pro1.oneYear", "pro2.oneYear", "pro3.oneYear", "lite.oneYear"]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .yearly),
                              PlanEntity(type: .proII, subscriptionCycle: .yearly),
                              PlanEntity(type: .proIII, subscriptionCycle: .yearly),
                              PlanEntity(type: .lite, subscriptionCycle: .yearly)]

        let sut = makeSUT(purchase: makePurchase(storeProductIdentifiers: identifiers, pricingProductIdentifiers: identifiers))
        let plans = await sut.accountPlanProducts(useAPIPrice: false)
        XCTAssertEqual(plans, expectedResult)
    }

    func testAccountPlanProducts_usingAPIPrice_shouldReturnAPIPrice_andCurrencyCode() async {
        let identifiers = ["pro1.oneYear", "pro2.oneYear", "pro3.oneYear", "lite.oneYear"]
        let expectedResult = [
            PlanEntity(type: .proI, subscriptionCycle: .yearly),
            PlanEntity(type: .proII, subscriptionCycle: .yearly),
            PlanEntity(type: .proIII, subscriptionCycle: .yearly),
            PlanEntity(type: .lite, subscriptionCycle: .yearly)
        ]
        // Written as strings because a `Decimal` float literal is not exact: `1111.11` parses as
        // 1111.1099999999997952, while the price the repository computes is exactly 1111.11.
        let expectedPrices = ["1111.11", "2222.22", "3333.33", "4444.44"].compactMap { Decimal(string: $0) }

        let mockPurchase = makePurchase(storeProductIdentifiers: identifiers)
        mockPurchase._pricing = MockMEGAPricing(
            productList: [
                MockPricingProduct(proLevel: .proI, localPrice: 111111, iOSID: "pro1.oneYear"),
                MockPricingProduct(proLevel: .proII, localPrice: 222222, iOSID: "pro2.oneYear"),
                MockPricingProduct(proLevel: .proIII, localPrice: 333333, iOSID: "pro3.oneYear"),
                MockPricingProduct(proLevel: .lite, localPrice: 444444, iOSID: "lite.oneYear")
            ]
        )
        mockPurchase._currency = MockMEGACurrency(localCurrencyName: "USD", localCurrencySymbol: "USD")
        let sut = makeSUT(purchase: mockPurchase)
        let plans = await sut.accountPlanProducts(useAPIPrice: true)
        XCTAssertEqual(plans, expectedResult)
        // `PlanEntity`'s equality only covers the type and the cycle, so the prices are asserted separately.
        XCTAssertEqual(plans.compactMap(\.apiPrice?.price), expectedPrices)
        XCTAssertTrue(plans.allSatisfy { $0.apiPrice?.currency == "USD" })
    }

    func testAccountPlanProducts_notUsingAPIPrice_shouldNotCarryAnAPIPrice() async {
        let mockPurchase = makePurchase(storeProductIdentifiers: ["pro1.oneYear"])
        mockPurchase._pricing = MockMEGAPricing(
            productList: [MockPricingProduct(proLevel: .proI, localPrice: 111111, iOSID: "pro1.oneYear")]
        )
        let sut = makeSUT(purchase: mockPurchase)

        let plans = await sut.accountPlanProducts(useAPIPrice: false)

        XCTAssertNil(plans.first?.apiPrice)
    }

    /// A product live in App Store Connect that the API does not price. The two catalogues only overlap,
    /// so a product with no pricing entry has no storage, transfer, price or offer to be built from.
    func testAccountPlanProducts_withAStoreProductMissingFromThePricing_shouldSkipIt() async {
        let sut = makeSUT(purchase: makePurchase(
            storeProductIdentifiers: ["pro1.oneMonth", "pro3.oneMonth"],
            pricingProductIdentifiers: ["pro1.oneMonth"]
        ))

        let plans = await sut.accountPlanProducts(useAPIPrice: false)

        XCTAssertEqual(plans.map(\.productIdentifier), ["pro1.oneMonth"])
    }

    /// With nothing priced there is nothing to build a plan out of, so no plan is built rather than an
    /// empty shell of one.
    func testAccountPlanProducts_whenThePricingListsNothing_shouldReturnNoPlans() async {
        let sut = makeSUT(purchase: makePurchase(storeProductIdentifiers: ["pro1.oneMonth"]))

        let plans = await sut.accountPlanProducts(useAPIPrice: false)

        XCTAssertTrue(plans.isEmpty)
    }

    /// The App Store returns the products in its own order, so a product's position in that list says
    /// nothing about where its plan sits in the pricing: every detail is read at the index the product
    /// resolves to.
    func testAccountPlanProducts_whenTheCataloguesAreOrderedDifferently_shouldReadTheMatchingPricingEntry() async {
        let mockPurchase = makePurchase(storeProductIdentifiers: ["pro1.oneMonth", "pro3.oneMonth"])
        mockPurchase._pricing = MockMEGAPricing(
            productList: [
                MockPricingProduct(proLevel: .proIII, storageGB: 16384, transferGB: 16384, iOSID: "pro3.oneMonth"),
                MockPricingProduct(proLevel: .proI, storageGB: 400, transferGB: 1024, iOSID: "pro1.oneMonth")
            ]
        )
        let sut = makeSUT(purchase: mockPurchase)

        let plans = await sut.accountPlanProducts(useAPIPrice: false)

        let proI = plans.first { $0.productIdentifier == "pro1.oneMonth" }
        let proIII = plans.first { $0.productIdentifier == "pro3.oneMonth" }
        XCTAssertEqual(proI?.storageLimit, 400)
        XCTAssertEqual(proI?.transferLimit, 1024)
        XCTAssertEqual(proIII?.storageLimit, 16384)
        XCTAssertEqual(proIII?.transferLimit, 16384)
    }

    /// Attaching an offer to the wrong plan is what makes a plan advertise a campaign belonging to another.
    func testAccountPlanProducts_shouldAttachTheOfferOfTheMatchingPricingEntry() async {
        let mockPurchase = makePurchase(storeProductIdentifiers: ["pro1.oneMonth", "pro2.oneMonth"])
        mockPurchase._pricing = MockMEGAPricing(
            productList: [
                MockPricingProduct(proLevel: .proI, iOSID: "pro1.oneMonth"),
                MockPricingProduct(proLevel: .proII, iOSID: "pro2.oneMonth", mobileOffer: MockMobileOffer(id: "black-friday"))
            ]
        )
        let sut = makeSUT(purchase: mockPurchase)

        let plans = await sut.accountPlanProducts(useAPIPrice: false)

        XCTAssertNil(plans.first { $0.productIdentifier == "pro1.oneMonth" }?.mobileOffer)
        XCTAssertEqual(plans.first { $0.productIdentifier == "pro2.oneMonth" }?.mobileOffer?.id, "black-friday")
    }

    // MARK: Restore purchase
    func testRestorePurchase_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchase_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        
        await sut.deRegisterRestoreDelegate()
        XCTAssertFalse(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseCalled_shouldReturnTrue() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        sut.restorePurchase()
        XCTAssertTrue(mockPurchase.restorePurchaseCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from successfulRestorePublisher")
        sut.successfulRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.successfulRestore(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_incompleteRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from incompleteRestorePublisher")
        sut.incompleteRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.incompleteRestore()
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_failedRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "Test Error")
        sut.failedRestorePublisher
            .sink { errorEntity in
                XCTAssertEqual(errorEntity.errorCode, expectedError.errorCode)
                XCTAssertEqual(errorEntity.errorMessage, expectedError.errorMessage)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.failedRestore(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Purchase plan
    func testPurchasePlan_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePlan_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        
        await sut.deRegisterPurchaseDelegate()
        XCTAssertFalse(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePublisher_successPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive success purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.successfulPurchase(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testPurchasePublisher_failedPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        
        let exp = expectation(description: "Should receive failed purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedPurchase(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Submit receipt
    func testSubmitReceiptPublisher_failedResult_shouldSendToPublisher() {
        let sut = AccountPlanPurchaseRepository(purchase: MockMEGAPurchase(), sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: -11, errorMessage: nil)
        
        let exp = expectation(description: "Should receive failed submit receipt result")
        sut.submitReceiptResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedSubmitReceipt(expectedError.errorCode)
        wait(for: [exp], timeout: 1)
    }
    
    func testStartMonitoringSubmitReceiptAfterPurchase_whenCalled_shouldSetIsSubmittingReceiptValueToMonitoringStatus() {
        let isSubmittingReceipt = Bool.random()
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(
            purchase: MockMEGAPurchase(isSubmittingReceipt: isSubmittingReceipt),
            currentUserSource: currentUserSource
        )
        
        sut.startMonitoringSubmitReceiptAfterPurchase()
        
        XCTAssertEqual(currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.value, isSubmittingReceipt)
    }
    
    func testEndMonitoringPurchaseReceipt_whenCalled_shouldSetMonitoringStatusToFalse() {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(
            purchase: MockMEGAPurchase(isSubmittingReceipt: true),
            currentUserSource: currentUserSource
        )
        
        sut.endMonitoringPurchaseReceipt()
        
        XCTAssertEqual(currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.value, false)
    }

    func testIsSubmittingReceiptAfterPurchase_whenCalled_shouldReturnCurrentSourceValue() {
        assertIsSubmittingReceiptAfterPurchase(true)
        
        assertIsSubmittingReceiptAfterPurchase(false)
    }
    
    private func assertIsSubmittingReceiptAfterPurchase(_ value: Bool) {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(currentUserSource: currentUserSource)
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(value)
        
        XCTAssertEqual(sut.isSubmittingReceiptAfterPurchase, value)
    }

    func testMonitorSubmitReceiptAfterPurchase_shouldPublishChanges() {
        let currentUserSource = CurrentUserSource(sdk: MockSdk())
        let sut = makeSUT(currentUserSource: currentUserSource)
        var receivedValues: [Bool] = []
        
        let expectation = expectation(description: "Should receive monitoring state changes")
        expectation.expectedFulfillmentCount = 2
        let cancellable = sut.monitorSubmitReceiptAfterPurchase
            .dropFirst()
            .sink {
                receivedValues.append($0)
                expectation.fulfill()
            }

        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(true)
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(false)
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValues, [true, false], "Publisher should emit correct sequence")
        
        cancellable.cancel()
    }
    
    func testSuccessSubmitReceipt_whenCalled_shouldEmitSubmitReceiptResultAndUpdateMonitorSubmitReceipt() {
        let sut = makeSUT(purchase: MockMEGAPurchase(isSubmittingReceipt: false))
        
        let exp = expectation(description: "Should receive success submit receipt result")
        sut.submitReceiptResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Expected success, but received failure: \(result)")
                }
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.successSubmitReceipt()
        
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.isSubmittingReceiptAfterPurchase, false)
    }

    private var locale: Locale {
        Locale(identifier: "en_US")
    }

    // MARK: - Helper
    private func makeSUT(
        purchase: MockMEGAPurchase = MockMEGAPurchase(),
        sdk: MockSdk = MockSdk(),
        currentUserSource: CurrentUserSource = CurrentUserSource(sdk: MockSdk())
    ) -> AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(
            purchase: purchase,
            sdk: sdk,
            currentUserSource: currentUserSource
        )
    }

    /// The two catalogues the repository holds: what the App Store sells, and what the API prices. They
    /// are given separately because a plan can appear in one and not the other.
    private func makePurchase(
        storeProductIdentifiers: [String],
        pricingProductIdentifiers: [String]? = nil
    ) -> MockMEGAPurchase {
        let purchase = MockMEGAPurchase(
            productPlans: storeProductIdentifiers.map { MockSKProduct(identifier: $0, price: "1", priceLocale: locale) }
        )
        if let pricingProductIdentifiers {
            purchase._pricing = MockMEGAPricing(productList: pricingProductIdentifiers.map { MockPricingProduct(iOSID: $0) })
        }
        return purchase
    }
}
