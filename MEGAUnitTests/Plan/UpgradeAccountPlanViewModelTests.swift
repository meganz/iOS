import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private let freePlan = AccountPlanEntity(type: .free, name: "Free")
    private let proI_monthly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly)
    private let proI_yearly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)
    private let proII_monthly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly)
    private let proII_yearly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly)
    private let proIII_monthly = AccountPlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly)
    
    // MARK: - Init
    func testInit_registerDelegates_shouldRegisterDelegates() async {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.registerDelegateTask?.value
        XCTAssertTrue(mockUseCase.registerRestoreDelegateCalled == 1)
    }
    
    func testInit_setUpPlansForFreeAccount_shouldSetupPlanData() async {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [proI_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .free)
        XCTAssertEqual(sut.recommendedPlanType, .proI)
    }
    
    func testInit_setUpPlansForProAccount_recurringMonthly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
        XCTAssertEqual(sut.filteredPlanList, [proI_monthly, proII_monthly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    func testInit_setUpPlansForProAccount_recurringYearly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [proI_yearly, proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    func testInit_setUpPlansForProAccount_oneTimePurchase_shouldSetupPlanData() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [proI_yearly, proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    // MARK: - Current plan
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, freePlan)
    }

    func testCurrentPlanValue_freePlan_shouldNotBeNil() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, nil)
    }
    
    func testCurrentPlanName_shouldMatchCurrentPlanName() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlanName, "Free")
    }
    
    func testCurrentPlanValue_shouldMatchCurrentPlan() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, proI_monthly)
    }
    
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, proI_yearly)
        XCTAssertNotEqual(sut.currentPlan, proI_monthly)
    }
    
    // MARK: - Recommended plan
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanFree_shouldBeProI() {
        let details = AccountDetailsEntity(proLevel: .free)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }

    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanLite_shouldBeProI() {
        let details = AccountDetailsEntity(proLevel: .lite)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProI_shouldBeProII() {
        let details = AccountDetailsEntity(proLevel: .proI)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProII_shouldBeProIII() {
        let details = AccountDetailsEntity(proLevel: .proII)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, .proIII)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProIII_shouldHaveNoRecommendedPlanType() {
        let details = AccountDetailsEntity(proLevel: .proIII)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    // MARK: - Selected plan type
    func testSelectedPlanTypeName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, proI_monthly.name)
    }
    
    func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, proI_monthly.type)
    }

    func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proI_monthly)
        XCTAssertNotEqual(sut.selectedPlanType, proI_monthly.type)
    }

    // MARK: - Selected term tab
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()

        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    func testSelectedCycleTab_oneTimePurchaseMonthly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    func testSelectedCycleTab_oneTimePurchaseYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    func testSelectedCycleTab_recurringPlanYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    func testSelectedCycleTab_recurringPlanMonthly_defaultShouldBeMonthly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
    }

    // MARK: - Buy button
    func testIsShowBuyButton_freeAccount_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .free, subscriptionCycle: .none)
        let planList = [proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
    }

    func testIsShowBuyButton_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_monthly)
        sut.selectedCycleTab = .yearly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButton_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_yearly)
        sut.selectedCycleTab = .monthly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButtonWithRecurringPlanMonthly_selectSamePlanTypeOnYearlyTab_thenSwitchedToMonthlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .yearly
        sut.setSelectedPlan(proI_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .monthly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButtonWithRecurringPlanYearly_selectSamePlanTypeOnMonthlyTab_thenSwitchedToYearlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .monthly
        sut.setSelectedPlan(proI_monthly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .yearly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    // MARK: - Plan list
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.selectedCycleTab = .monthly
        XCTAssertEqual(sut.filteredPlanList, [proI_monthly, proII_monthly])
    }
    
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.selectedCycleTab = .yearly
        XCTAssertEqual(sut.filteredPlanList, [proI_yearly, proII_yearly])
    }
    
    // MARK: - Restore
    func testRestore_tappedRestoreButton_shouldCallRestorePlan() async {
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        let sut = UpgradeAccountPlanViewModel(accountDetails: AccountDetailsEntity(proLevel: .free),
                                              purchaseUseCase: mockUseCase)
        
        sut.didTap(.restorePlan)
        await sut.restorePlanTask?.value
        XCTAssertTrue(mockUseCase.restorePurchaseCalled == 1)
    }
    
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() throws {
        let details = AccountDetailsEntity(proLevel: .free)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: MockAccountPlanPurchaseUseCase())
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.success))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore success")
            return
        }
        XCTAssertEqual(status, .success)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() throws {
        let details = AccountDetailsEntity(proLevel: .free)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: MockAccountPlanPurchaseUseCase())
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.incomplete))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore incomplete")
            return
        }
        XCTAssertEqual(status, .incomplete)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() throws {
        let details = AccountDetailsEntity(proLevel: .free)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: MockAccountPlanPurchaseUseCase())
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let details = AccountDetailsEntity(proLevel: .free)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: MockAccountPlanPurchaseUseCase())
        
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Purchase
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(proI_monthly)
        
        sut.didTap(.buyPlan)
        await sut.buyPlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let details = AccountDetailsEntity(proLevel: .free)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: MockAccountPlanPurchaseUseCase())
        await sut.setUpPlanTask?.value
        
        sut.setAlertType(UpgradeAccountPlanAlertType.purchase(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    // MARK: - Snackbar
    func testSnackBar_selectedCurrentRecurringAccount_shouldShowSnackBar() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(proI_monthly)
        
        XCTAssertTrue(sut.isShowSnackBar)
        XCTAssertEqual(sut.snackBarType, .currentRecurringPlanSelected)
    }
    
    func testSnackBar_selectedCurrentOneTimeAccount_shouldNotShowSnackBar() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(proI_monthly)
        
        XCTAssertFalse(sut.isShowSnackBar)
        XCTAssertEqual(sut.snackBarType, .none)
    }
    
    func testSnackBarType_isShowSnackBarSetToFalse_shouldBeNone() async {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(proI_monthly)
        XCTAssertTrue(sut.isShowSnackBar)
        
        let exp = expectation(description: "Set snackBarViewModel snackBarViewModel to false")
        let snackBarViewModel = sut.snackBarViewModel()
        snackBarViewModel.$isShowSnackBar
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)

        snackBarViewModel.isShowSnackBar = false
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(sut.snackBarType, .none)
    }
}
