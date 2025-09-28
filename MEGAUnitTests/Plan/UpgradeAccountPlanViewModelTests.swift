import Accounts
import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
import MEGAStoreKit
import MEGAUIComponent
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var mockAccountUseCase: MockAccountUseCase!

    private var subscriptions = Set<AnyCancellable>()
    private let storageMax = 20

    override func tearDown() async throws {
        mockAccountUseCase = nil
    }

    // MARK: - Init
    @MainActor
    func testInit_registerDelegates_shouldRegisterDelegates() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let (sut, mockUseCase) = makeSUT(
            accountDetails: details
        )
        
        await sut.registerDelegateTask?.value
        XCTAssertTrue(mockUseCase.registerRestoreDelegateCalled == 1)
    }
    
    @MainActor
    func testInit_setUpPlansForFreeAccount_shouldSetupPlanData() async {
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free), planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.subscriptionPurchaseChipOptions.map(\.title),
                       [Strings.Localizable.monthly, Strings.Localizable.yearly])
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        let expectedSelectedChip = sut.subscriptionPurchaseChipOptions.first(
            where: { $0.title == Strings.Localizable.yearly })
        XCTAssertEqual(sut.selectedSubscriptionPurchaseChip, expectedSelectedChip)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .free)
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.maxStorageFromPlans, PlanEntity.proI_yearly.storageLimit.toGBString())
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_recurringMonthly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
        let expectedSelectedChip = sut.subscriptionPurchaseChipOptions.first(
            where: { $0.title == Strings.Localizable.monthly })
        XCTAssertEqual(sut.selectedSubscriptionPurchaseChip, expectedSelectedChip)
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.maxStorageFromPlans, PlanEntity.proII_yearly.storageLimit.toGBString())
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_recurringYearly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_oneTimePurchase_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    // MARK: - Current plan
    @MainActor
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, .freePlan)
    }

    @MainActor
    func testCurrentPlanValue_freePlan_shouldNotBeNil() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, nil)
    }
    
    @MainActor
    func testCurrentPlanName_shouldMatchCurrentPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlanName, "Free")
    }
    
    @MainActor
    func testCurrentPlanValue_shouldMatchCurrentPlan() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, .proI_monthly)
    }
    
    @MainActor
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, .proI_yearly)
        XCTAssertNotEqual(sut.currentPlan, .proI_monthly)
    }
    
    // MARK: - Recommended plan
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanFree_shouldBeProI() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }

    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanLite_shouldBeProI() {
        let details = AccountDetailsEntity.build(proLevel: .lite)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProI_shouldBeProII() {
        let details = AccountDetailsEntity.build(proLevel: .proI)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProII_shouldBeProIII() {
        let details = AccountDetailsEntity.build(proLevel: .proII)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, .proIII)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProIII_shouldHaveNoRecommendedPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .proIII)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProLite_shouldBeProI() async {
        let planList: [PlanEntity] = [.proLite_monthly, .proI_monthly, .proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding(isFreeAccountFirstLogin: false)
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboardingRevampFeatureFlagOn_shouldSetCorrectPlan() async {
        let testCase: [(currentPlan: AccountTypeEntity, recommendedPlan: AccountTypeEntity?, selectedPlanType: AccountTypeEntity?)] = [
            (.free, .proI, .proI),
            (.lite, .proI, .proI),
            (.starter, .proI, .proI),
            (.basic, .proI, .proI),
            (.essential, .proI, .proI),
            (.proI, .proII, .proII),
            (.proII, .proIII, .proIII),
            (.proIII, nil, nil)
        ]
        for (current, recommended, selectedPlanType) in testCase {
            let (sut, _) = makeSUT(
                accountDetails: AccountDetailsEntity.build(proLevel: current),
                viewType: .onboarding(isFreeAccountFirstLogin: false)
            )
            
            await sut.setUpPlanTask?.value
            
            XCTAssertEqual(sut.recommendedPlanType, recommended)
            XCTAssertEqual(sut.selectedPlanType, selectedPlanType)
        }
    }
    
    // MARK: - Selected plan type
    @MainActor
    func testSelectedPlanTypeName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, PlanEntity.proI_monthly.name)
    }
    
    @MainActor
    func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }

    @MainActor
    func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proI_monthly)
        XCTAssertNotEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }

    // MARK: - Selected term tab
    @MainActor
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .free)

        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_oneTimePurchaseMonthly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_oneTimePurchaseYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_recurringPlanYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_recurringPlanMonthly_defaultShouldBeMonthly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
    }

    // MARK: - Buy button
    @MainActor
    func testBuyButtons_freeAccount() async {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_yearly)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proII_yearly.type.toAccountTypeDisplayName()
                ))
            ]
        )
    }

    @MainActor
    func testBuyButtons_freeAccount_whenShouldProvideExternalPurchase_withSameCurrency() async {
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            apiPrice: .sample(75, currency: "USD"),
            appStorePrice: .sample(100, currency: "USD")
        )
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, plan]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(
            externalPurchaseUseCase: MockExternalPurchaseUseCase(shouldProvideExternalPurchase: true),
            accountDetails: details,
            planList: planList
        )
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(plan)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title("Pro I")),
                MEGAButton(
                    Strings.Localizable.UpgradeAccountPlan.Button.BuyViaWeb.save("25%"),
                    type: .secondary
                )
            ]
        )
    }

    @MainActor
    func testBuyButtons_freeAccount_whenShouldProvideExternalPurchase_withDifferentCurrency() async {
        let plan = PlanEntity(
            type: .proII,
            subscriptionCycle: .yearly,
            apiPrice: .sample(100, currency: "EUR"),
            appStorePrice: .sample(120, currency: "USD")
        )
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proII_monthly, plan]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(
            externalPurchaseUseCase: MockExternalPurchaseUseCase(shouldProvideExternalPurchase: true),
            accountDetails: details,
            planList: planList
        )
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(plan)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title("Pro II")),
                MEGAButton(
                    Strings.Localizable.UpgradeAccountPlan.Button.BuyViaWeb.saveUpTo("15%"),
                    type: .secondary
                )
            ]
        )
    }

    @MainActor
    func testBuyButtons_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_monthly)
        sut.selectedCycleTab = .yearly
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proII_yearly.type.toAccountTypeDisplayName()
                ))
            ]
        )
    }
    
    @MainActor
    func testBuyButtons_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_yearly)
        sut.selectedCycleTab = .monthly
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proII_yearly.type.toAccountTypeDisplayName()
                ))
            ]
        )
    }
    
    @MainActor
    func testBuyButtonsWithRecurringPlanMonthly_selectSamePlanTypeOnYearlyTab_thenSwitchedToMonthlyTab() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .yearly
        sut.setSelectedPlan(.proI_yearly)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proI_yearly.type.toAccountTypeDisplayName()
                ))
            ]
        )

        sut.selectedCycleTab = .monthly
        await sut.updateBuyButtonsTask?.value
        XCTAssertTrue(sut.buyButtons.isEmpty)
    }
    
    @MainActor
    func testBuyButtonsWithRecurringPlanYearly_selectSamePlanTypeOnMonthlyTab_thenSwitchedToYearlyTab() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .monthly
        sut.setSelectedPlan(.proI_monthly)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proI_monthly.type.toAccountTypeDisplayName()
                ))
            ]
        )

        sut.selectedCycleTab = .yearly
        await sut.updateBuyButtonsTask?.value
        XCTAssertTrue(sut.buyButtons.isEmpty)
    }

    @MainActor
    func testBuyButtons_whenAPIPriceIsNil_shouldNotProvideExternalPurchaseButton() async {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let apiPriceZeroPlan = {
            var plan = PlanEntity.proII_yearly
            plan.apiPrice = nil
            return plan
        }()
        let planList: [PlanEntity] = [.proII_monthly, apiPriceZeroPlan]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(
            externalPurchaseUseCase: MockExternalPurchaseUseCase(shouldProvideExternalPurchase: true),
            accountDetails: details,
            planList: planList
        )
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        await fulfillment(of: [exp], timeout: 0.5)

        sut.setSelectedPlan(apiPriceZeroPlan)
        await sut.updateBuyButtonsTask?.value

        assertButtonsEqual(
            lhs: sut.buyButtons,
            rhs: [
                MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
                    PlanEntity.proII_yearly.type.toAccountTypeDisplayName()
                ))
            ]
        )
    }

    // MARK: - Plan list
    @MainActor
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let exp = expectation(description: "Set selected plan term")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.selectedCycleTab = .monthly
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
    }
    
    @MainActor
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let exp = expectation(description: "Set selected plan term")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.selectedCycleTab = .yearly
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
    }
    
    // MARK: - Restore
    @MainActor
    func testRestore_tappedRestoreButton_shouldCallRestorePlan() async {
        let (sut, mockUseCase) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.didTap(.restorePlan)
        XCTAssertTrue(mockUseCase.restorePurchaseCalled == 1)
    }
    
    @MainActor
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.success))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore success")
            return
        }
        XCTAssertEqual(status, .success)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.incomplete))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore incomplete")
            return
        }
        XCTAssertEqual(status, .incomplete)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Validate active subscriptions
    @MainActor
    func testPurchasePlan_validateActiveSubscriptions_haveActiveCancellableSubscription_shouldThrowHaveCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveCancellablePlan)
        }
    }
    
    @MainActor
    func testPurchasePlan_validateActiveSubscriptions_haveActiveNonCancellableSubscription_shouldThrowHaveNonCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: nonCancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)

        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveNonCancellablePlan)
        }
    }
    
    // MARK: - Cancel active subscription
    @MainActor
    func testCancelActiveSubscription_shouldCancelSubscription_shouldSuccessValidateSubscription() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let expectedAccountPlan = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .none, subscriptionMethodId: .balance)
        let mockSubscriptionsUseCase = MockSubscriptionsUseCase(requestResult: .success)
        let (sut, _) = makeSUT(
            subscriptionsUseCase: mockSubscriptionsUseCase,
            accountDetails: details,
            accountDetailsResult: .success(expectedAccountPlan)
        )
        
        await sut.cancelActiveCancellableSubscription()
        XCTAssertTrue(mockSubscriptionsUseCase.cancelSubscriptionsWithReasonString_calledTimes == 1)
        
        do {
            try sut.validateActiveSubscriptions()
        } catch {
            XCTFail("Active Subscription error \(error) is not expected.")
        }
    }
    
    // MARK: - Purchase
    @MainActor
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        let (sut, mockUseCase) = makeSUT(
            accountDetails: details,
            planList: planList
        )
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        sut.didTap(.buyPlan)
        await sut.buyPlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    @MainActor
    func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
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
    @MainActor
    func testSnackBar_selectedCurrentRecurringAccount_shouldShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertEqual(sut.snackBar?.message, PlanSelectionSnackBarType.currentRecurringPlanSelected.title)
    }
    
    @MainActor
    func testSnackBar_selectedCurrentOneTimeAccount_shouldNotShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertNil(sut.snackBar)
    }
        
    // MARK: - Ads
    @MainActor func testSetupExternalAds_externalAdsEnabled_shouldBeTrue() {
        assertSetupExternalAds(isExternalAdsFlagEnabled: true)
    }
    
    @MainActor func testSetupExternalAds_externalAdsDisabled_shouldBeFalse() {
        assertSetupExternalAds(isExternalAdsFlagEnabled: false)
    }
    
    @MainActor func assertSetupExternalAds(isExternalAdsFlagEnabled: Bool) {
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            isExternalAdsFlagEnabled: isExternalAdsFlagEnabled
        )
        
        XCTAssertEqual(sut.isExternalAdsActive, isExternalAdsFlagEnabled)
    }
    
    // - MARK: Track events
    @MainActor
    func testPurchasePlan_purchaseProI_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proI_yearly, shouldTrack: [BuyProIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proII_yearly, shouldTrack: [BuyProIIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProIII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proIII_yearly, shouldTrack: [BuyProIIIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProLite_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proLite_yearly, shouldTrack: [BuyProLiteEvent()])
    }
    
    @MainActor
    func testCancel_tappedCancelButton_shouldTrackCancelUpgradeEvent() {
        let harness = Harness()
        harness.testCancelUpgrade()
    }
    
    @MainActor
    func testViewLoad_shouldTrackScreenViewEvent() {
        let harness = Harness()
        harness.testViewOnLoad()
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsTrue_shouldTrackButtonTapEventForAdsSurePath() async {
        let harness = Harness(isFromAds: true)
        
        await harness.testBuyPlan(
            .proLite_yearly,
            shouldTrack: [
                AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent(),
                BuyProLiteEvent()
            ]
        )
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseAndEligibleForAdsEvent_shouldTrackButtonTapEventForAdsMaybePath() async {
        // Ads was closed within the last two days and
        // only less than half of storage quota is used
        let largestValidSize = (storageMax - 1) / 2
        let lessThanHalfOfStorage = Int.random(in: 0...largestValidSize)
        await assertAdsEventForMaybePath(
            storageMax: storageMax,
            storageUsed: lessThanHalfOfStorage,
            lastCloseAdsDate: Date(),
            expectedAdsEvent: AdsUpgradeAccountPlanPageBuyButtonPressedEvent()
        )
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseButAdsIsClosedMoreThanTwoDays_shouldNotTrackButtonTapEventForAdsMaybePath() async throws {
        let threeDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: Date()))
        
        await assertAdsEventForMaybePath(lastCloseAdsDate: threeDaysAgo, expectedAdsEvent: nil)
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseButHasUsedMoreThanHalfOfStorage_shouldNotTrackButtonTapEventForAdsMaybePath() async throws {
        let moreThanHalfOfStorage = Int.random(in: (storageMax / 2)...storageMax)
        await assertAdsEventForMaybePath(storageMax: storageMax, storageUsed: moreThanHalfOfStorage, expectedAdsEvent: nil)
    }
    
    @MainActor private func assertAdsEventForMaybePath(
        storageMax: Int = 20,
        storageUsed: Int = 0,
        lastCloseAdsDate: Date = Date(),
        expectedAdsEvent: (any EventIdentifier)?
    ) async {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: Int64(storageUsed),
            storageMax: Int64(storageMax),
            proLevel: .free
        )
        let harness = Harness(details: accountDetails, lastCloseAdsDate: lastCloseAdsDate, isFromAds: false)
        var events: [any EventIdentifier] = []
        
        if let expectedAdsEvent {
            events.append(expectedAdsEvent)
        }
        events.append(BuyProLiteEvent())
        
        await harness.testBuyPlan(
            .proLite_yearly,
            shouldTrack: events
        )
    }

    @MainActor func testGetStartedButtonTapped() {
        let harness = Harness()
        XCTAssertFalse(harness.sut.isDismiss)
        harness.testGetStartedButtonTapped()
        XCTAssertTrue(harness.sut.isDismiss)
    }

    @MainActor func testMayBeLaterButtonTapped() {
        let harness = Harness()
        XCTAssertFalse(harness.sut.isDismiss)
        harness.testMayBeLaterButtonTapped()
        XCTAssertTrue(harness.sut.isDismiss)
    }

    // MARK: - External Purchase

    @MainActor
    func testDidTapBuyExternally_shouldOpenExternalLink() async {
        nonisolated(unsafe) var urlOpened = [URL]()
        
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let expectedURL = URL(string: "https://www.example.com")!
        let (sut, _) = makeSUT(
            externalPurchaseUseCase: MockExternalPurchaseUseCase(
                shouldProvideExternalPurchase: true,
                externalPurchaseLink: .success(expectedURL)
            ),
            accountDetails: details,
            planList: planList,
            canOpenURL: { _ in true },
            openURL: { urlOpened.append($0) }
        )
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        sut.didTap(.buyExternally)
        await sut.buyPlanTask?.value
        
        XCTAssertEqual(urlOpened, [expectedURL])
    }

    @MainActor
    func testDidTapBuyExternally_whenAPIPriceNil_shouldNotOpenExternalLink() async {
        nonisolated(unsafe) var urlOpened = [URL]()
        let details = AccountDetailsEntity.build(proLevel: .free)
        let apiPriceZeroPlan = {
            var plan = PlanEntity.proI_yearly
            plan.apiPrice = nil
            return plan
        }()
        let planList: [PlanEntity] = [.proI_monthly, apiPriceZeroPlan, .proII_monthly, .proII_yearly]
        let (sut, mockUseCase) = makeSUT(
            externalPurchaseUseCase: MockExternalPurchaseUseCase(
                shouldProvideExternalPurchase: true,
                externalPurchaseLink: .success(.random)
            ),
            accountDetails: details,
            planList: planList,
            canOpenURL: { _ in true },
            openURL: { urlOpened.append($0) }
        )

        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(apiPriceZeroPlan)

        sut.didTap(.buyExternally)
        await sut.buyPlanTask?.value

        XCTAssertEqual(urlOpened, [])
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }

    // MARK: - Free plan view model
    
    @MainActor
    func testFreePlanViewModel_viewType_shouldReturnCorrectInstance() {
        let viewTypes = [UpgradeAccountPlanViewType.upgrade,
                         .onboarding(isFreeAccountFirstLogin: true),
                         .onboarding(isFreeAccountFirstLogin: false)]
        for viewType in viewTypes {
            let (sut, _) = makeSUT(
                accountDetails: .build(proLevel: .proI),
                viewType: viewType)
            XCTAssertEqual(sut.freePlanViewModel != nil, viewType != .upgrade)
        }
    }
    
    @MainActor
    func testAutoRenewDescription_linkIsCorrect() {
        let (sut, _) = makeSUT(
            accountDetails: .build(proLevel: .proI),
            viewType: .upgrade)
        
        let fullText = Strings.Localizable.SubscriptionPurchase.autoRenewDescription
        let tappableText = fullText.subString(from: "[L]", to: "[/L]") ?? ""
        let fullTextWithoutFormatters = fullText
            .replacingOccurrences(of: "[L]", with: "")
            .replacingOccurrences(of: "[/L]", with: "")
        
        let description = sut.autoRenewDescription
        XCTAssertEqual(description.fullText, fullTextWithoutFormatters)
        XCTAssertEqual(description.tappableText, tappableText)
        XCTAssertEqual(description.linkString, "https://support.apple.com/118428")
    }
    
    @MainActor
    func testProPlanBenefits_correct() {
        let expectedBenefits =  [
            Strings.Localizable.Password.Protected.Links.title,
            Strings.Localizable.Links.With.Expiry.Dates.title,
            Strings.Localizable.SubscriptionPurchase.Benefits.Rewind.title,
            Strings.Localizable.SubscriptionPurchase.Benefits.CallsAndMeetings.title,
            Strings.Localizable.SubscriptionPurchase.Benefits.RubbishClearing.title,
            Strings.Localizable.General.prioritySupport]
        
        let (sut, _) = makeSUT(
            accountDetails: .build(proLevel: .free),
        )
        
        XCTAssertEqual(sut.benefitsOfProPlans, expectedBenefits)
    }

    // MARK: - Helper
    @MainActor
    func makeSUT(
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol = MockSubscriptionsUseCase(requestResult: .failure(.generic)),
        externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol = MockExternalPurchaseUseCase(),
        accountDetails: AccountDetailsEntity,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        planList: [PlanEntity] = [],
        isExternalAdsFlagEnabled: Bool = true,
        tracker: MockTracker = MockTracker(),
        viewType: UpgradeAccountPlanViewType = .upgrade,
        isFromAds: Bool = false,
        lastCloseAdsDate: Date? = nil,
        appVersion: String = "1.0.0",
        canOpenURL: @Sendable @escaping (URL) async -> Bool = { _ in true },
        openURL: @Sendable @escaping (URL) async -> Void = { _ in },
    ) -> (UpgradeAccountPlanViewModel, MockAccountPlanPurchaseUseCase) {
        mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let router = MockUpgradeAccountPlanRouter(isFromAds: isFromAds)
        let preferenceUseCase = MockPreferenceUseCase()
        if let lastCloseAdsDate {
            preferenceUseCase.dict[PreferenceKeyEntity.lastCloseAdsButtonTappedDate.rawValue] = lastCloseAdsDate
        }
        let sut = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: mockAccountUseCase,
            purchaseUseCase: mockPurchaseUseCase,
            subscriptionsUseCase: subscriptionsUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsFlagEnabled]),
            preferenceUseCase: preferenceUseCase,
            externalPurchaseUseCase: externalPurchaseUseCase,
            tracker: tracker,
            viewType: viewType,
            router: router,
            appVersion: appVersion,
            canOpenURL: canOpenURL,
            openURL: openURL
        )
        return (sut, mockPurchaseUseCase)
    }

    private func assertButtonsEqual(
        lhs: [MEGAButton],
        rhs: [MEGAButton]
    ) {
        XCTAssertEqual(lhs.count, rhs.count)
        for (l, r) in zip(lhs, rhs) {
            assertButtonEqual(lhs: l, rhs: r)
        }
    }

    private func assertButtonEqual(
        lhs: MEGAButton,
        rhs: MEGAButton
    ) {
        XCTAssertEqual(lhs.title?.description, rhs.title?.description)
        XCTAssertEqual(lhs.footer?.description, rhs.footer?.description)
        XCTAssertEqual(lhs.icon, rhs.icon)
        XCTAssertEqual(lhs.iconAlignment, rhs.iconAlignment)
        XCTAssertEqual(lhs.type, rhs.type)
        XCTAssertEqual(lhs.state, rhs.state)
    }

    private var cancellableSubscriptionMethod: PaymentMethodEntity {
        let methods: [PaymentMethodEntity] = [.ECP, .sabadell, .stripe2]
        return methods.randomElement() ?? .ECP
    }
    
    private var nonCancellableSubscriptionMethod: PaymentMethodEntity {
        let methods: [PaymentMethodEntity] = [.ECP, .sabadell, .stripe2, .itunes, .none]
        let nonCancellableMethod = Set(PaymentMethodEntity.allCases).subtracting(Set(methods))
        return Array(nonCancellableMethod).randomElement() ?? .balance
    }
    
    @MainActor
    class Harness {
        let sut: UpgradeAccountPlanViewModel
        let tracker = MockTracker()
        
        init(
            details: AccountDetailsEntity = AccountDetailsEntity.build(proLevel: .free),
            planList: [PlanEntity] = [.freePlan, .proI_yearly, .proII_yearly, .proIII_yearly, .proLite_yearly],
            lastCloseAdsDate: Date? = nil,
            isFromAds: Bool = false
        ) {
            let (sut, _) = UpgradeAccountPlanViewModelTests().makeSUT(
                accountDetails: details,
                planList: planList,
                tracker: tracker,
                isFromAds: isFromAds,
                lastCloseAdsDate: lastCloseAdsDate
            )
            self.sut = sut
        }
        
        func testBuyPlan(_ plan: PlanEntity, shouldTrack events: [any EventIdentifier]) async {
            await sut.setUpPlanTask?.value
            sut.setSelectedPlan(plan)
            
            sut.didTap(.buyPlan)
            await sut.buyPlanTask?.value
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: events
            )
        }
        
        func testCancelUpgrade() {
            sut.cancelUpgradeButtonTapped()
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [CancelUpgradeMyAccountEvent()]
            )
        }

        func testMayBeLaterButtonTapped() {
            sut.mayBeLaterButtonTapped()

            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [MaybeLaterUpgradeAccountButtonPressedEvent()]
            )
        }

        func testGetStartedButtonTapped() {
            sut.getStartedButtonTapped()

            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [GetStartedForFreeUpgradePlanButtonPressedEvent()]
            )
        }

        func testViewOnLoad() {
            sut.onLoad()
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [UpgradeAccountPlanScreenEvent()]
            )
        }
    }
}
