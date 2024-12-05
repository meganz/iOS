import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

final class ProfileViewModelTests: XCTestCase {
    var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testAction_onViewDidLoad_defaultValue() {
        let isStandardProAccount = true
        let isBilledProPlan = true
        let isSubscriptionHidden = !(isStandardProAccount && isBilledProPlan)
        let (sut, _) = makeSUT(
            isStandardProAccount: isStandardProAccount,
            isBilledProPlan: isBilledProPlan
        )
        let result = receivedSectionDataSource(
            from: sut,
            after: .onViewDidLoad
        )
        let expectedSections = ProfileViewModel.SectionCellDataSource(
            sectionOrder: sectionsOrder(isSubscriptionHidden: isSubscriptionHidden),
            sectionRows: sectionRows(isSubscriptionHidden: isSubscriptionHidden)
        )
        
        XCTAssertEqual(result, expectedSections)
    }
    
    func testAction_onViewDidLoad_shouldTrackAnalyticsEvent() {
        assertActionTracker(
            action: .onViewDidLoad,
            expectedEventIdentifiers: [ProfileScreenEvent()]
        )
    }
    
    func testAction_didTapBackUpRecoveryKey_shouldTrackAnalyticsEvent() {
        assertActionTracker(
            action: .didTapBackUpRecoveryKey,
            expectedEventIdentifiers: [BackupRecoveryKeyButtonPressedEvent()]
        )
    }
    
    func testAction_didTapLogout_shouldTrackAnalyticsEvent() {
        assertActionTracker(
            action: .didTapLogout,
            expectedEventIdentifiers: [LogoutButtonPressedEvent()]
        )
    }
    
    func testSectionsVisibility_withoutValidProAccount_shouldNotShowSubscriptionSection() {
        let (sut, _) = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        XCTAssertFalse(result?.sectionOrder.contains(.subscription) ?? true, "Subscription section should not appear for non-valid Pro accounts")
    }
    
    func testAction_onViewDidLoadWithoutValidProAccount_shouldShowCorrectSectionsAndRows() {
        let (sut, _) = makeSUT()
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        let expectedSections = ProfileViewModel.SectionCellDataSource(
            sectionOrder: sectionsOrder(),
            sectionRows: sectionRows())
        
        XCTAssertEqual(result, expectedSections)
    }
    
    func testAction_onViewDidLoad_whenSmsIsAllowed() {
        let isStandardProAccount = true
        let isBilledProPlan = true
        let isSubscriptionHidden = !(isStandardProAccount && isBilledProPlan)
        
        let (sut, _) = makeSUT(
            smsState: .optInAndUnblock, 
            isStandardProAccount: isStandardProAccount,
            isBilledProPlan: isBilledProPlan
        )
        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        let expectedResult = ProfileViewModel.SectionCellDataSource(
            sectionOrder: sectionsOrder(isSubscriptionHidden: isSubscriptionHidden),
            sectionRows: sectionRows(
                isSubscriptionHidden: isSubscriptionHidden,
                isSmsAllowed: true
            )
        )
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testSectionCells_whenAccountIsNotProFlexiBusinessNorMasterBusinessAccount_shouldNotIncludePlanSection() {
        testSectionCellsForAccountType(.free)
        testSectionCellsForAccountType(.proI)
        testSectionCellsForAccountType(.proII)
        testSectionCellsForAccountType(.proIII)
        testSectionCellsForAccountType(.lite)
    }
    
    func testSectionCells_whenAccountIsProFlexiAccount_shouldIncludePlanSection() {
       testSectionCellsForAccountType(.proFlexi, isPlanHidden: false)
    }
    
    func testSectionCells_whenAccountIsBusinessAccount_shouldIncludePlanSection() {
        testSectionCellsForAccountType(.business, isPlanHidden: false)
    }
    
    func testSectionCells_whenAccountIsMasterBusinessAccount_shouldIncludePlanSection() {
        testSectionCellsForAccountType(.business, isPlanHidden: false, isMasterBusinessAccount: true)
    }
    
    func testAction_changeEmail_emailCellShouldBeLoading() {
        let (sut, _) = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        let expectation = XCTestExpectation(description: "Expected change email cell to be loading in the profile section")
        
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .dropFirst(1)
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        sut.dispatch(.changeEmail)
        
        wait(for: [expectation], timeout: 3)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changeEmail(isLoading: true)}) ?? false
        )
    }
    
    func testAction_changePassword_passwordCellShouldBeLoading() {
        let (sut, _) = makeSUT()
        sut.dispatch(.onViewDidLoad)
        
        let expectation = XCTestExpectation(description: "Expected change password cell to be loading in the profile section")
        
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .dropFirst(1)
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.dispatch(.changePassword)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertTrue(
            result?.sectionRows[.profile]?
                .contains(where: { $0 == .changePassword(isLoading: true)}) ?? false
        )
    }
    
    @MainActor func testAction_changeEmail_shouldPresentChangeController() {
        let (sut, _) = makeSUT(
            multiFactorAuthCheckResult: true,
            multiFactorAuthCheckDelay: 0.5
        )
        sut.dispatch(.onViewDidLoad)
        
        test(
            viewModel: sut,
            actions: [ProfileAction.changeEmail],
            expectedCommands: [.changeProfile(requestedChangeType: .email, isTwoFactorAuthenticationEnabled: true)]
        )
    }
    
    @MainActor func testAction_changePassword_shouldPresentChangeController() {
        let (sut, _) = makeSUT(
            multiFactorAuthCheckResult: true,
            multiFactorAuthCheckDelay: 0.5
        )
        sut.dispatch(.onViewDidLoad)
        
        test(
            viewModel: sut,
            actions: [ProfileAction.changePassword],
            expectedCommands: [.changeProfile(requestedChangeType: .password, isTwoFactorAuthenticationEnabled: true)]
        )
    }
    
    @MainActor
    func testAction_cancelSubscription_shouldPresentCancelAccountPlan() async {
        let planType: AccountTypeEntity = [.proI, .proII, .proIII, .lite].randomElement() ?? .proI
        let subscription = PaymentMethodEntity.allCases.filter { $0 != .none }.randomElement() ?? .itunes
        let (sut, router) = makeSUT(
            accountType: planType,
            currentSubscription: AccountSubscriptionEntity(id: "123ABC", paymentMethodId: subscription)
        )
        
        sut.dispatch(.cancelSubscription)

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(router.showCancelAccountPlan_calledTimes, 1, "Expected showCancelAccountPlan to be called once.")
    }
    
    func testAction_cancelSubscription_shouldTrackAnalyticsEvent() {
        assertActionTracker(
            action: .cancelSubscription,
            expectedEventIdentifiers: [CancelSubscriptionButtonPressedEvent()]
        )
    }
    
    func testShouldShowPlanSection_whenAccountIsProFlexi_shouldIncludePlanSection() {
        testPlanSectionVisibility(
            accountType: .proFlexi,
            shouldBeShown: true
        )
    }

    func testShouldShowPlanSection_whenAccountIsBusiness_shouldIncludePlanSection() {
        testPlanSectionVisibility(
            accountType: .business,
            shouldBeShown: true
        )
    }

    func testShouldShowPlanSection_whenAccountIsMasterBusiness_shouldIncludePlanSection() {
        testPlanSectionVisibility(
            accountType: .business,
            isMasterBusinessAccount: true,
            shouldBeShown: true
        )
    }

    func testShouldShowPlanSection_whenAccountIsFree_shouldNotIncludePlanSection() {
        testPlanSectionVisibility(
            accountType: .free,
            shouldBeShown: false
        )
    }

    func testShouldShowCancelSubscriptionSection_whenStandardProAccountAndSubscription_shouldIncludeSubscriptionSection() {
        testSubscriptionSectionVisibility(
            isStandardProAccount: true,
            isBilledProPlan: true,
            shouldBeShown: true
        )
    }
    
    func testShouldShowCancelSubscriptionSection_whenStandardProAccountAndInvalidSubscription_shouldIncludeSubscriptionSection() {
        testSubscriptionSectionVisibility(
            isStandardProAccount: true,
            shouldBeShown: false
        )
    }

    func testShouldShowCancelSubscriptionSection_whenNotStandardProAccount_shouldNotIncludeSubscriptionSection() {
        testSubscriptionSectionVisibility(
            isBilledProPlan: true,
            shouldBeShown: false
        )
    }
    
    func testShouldShowCancelSubscriptionSection_whenCurrentUserHasMultipleBilledProPlans_shouldNotIncludeSubscriptionSection() {
        testSubscriptionSectionVisibility(
            hasMultipleBilledProPlan: true,
            shouldBeShown: false
        )
    }
    
    func testShouldShowCancelSubscriptionSection_whenNotStandardProAccountAndSubscription_shouldNotIncludeSubscriptionSection() {
        testSubscriptionSectionVisibility(shouldBeShown: false)
    }
    
    func testHasActiveBusinessAccount_shouldReturnCorrectValue() {
        let expectedValue = Bool.random()
        let (sut, _) = makeSUT(hasActiveBusinessAccount: expectedValue)
        XCTAssertEqual(sut.hasActiveBusinessAccount, expectedValue)
    }
    
    func testHasActiveProFlexiAccount_shouldReturnCorrectValue() {
        let expectedValue = Bool.random()
        let (sut, _) = makeSUT(hasActiveProFlexiAccount: expectedValue)
        XCTAssertEqual(sut.hasActiveProFlexiAccount, expectedValue)
    }
    
    func testAccountDetails_shouldReturnCorrectAccountDetails() {
        let expectedAccountType = AccountTypeEntity.allCases.randomElement() ?? .free
        let (sut, _) = makeSUT(accountType: expectedAccountType)
        XCTAssertEqual(sut.accountDetails, AccountDetailsEntity.build(proLevel: expectedAccountType))
    }
    
    func testDetermineBusinessAccountState_whenAccountIsActive_shouldReturnActive() {
        let (sut, _) = makeSUT(
            hasActiveBusinessAccount: true,
            hasBusinessAccountInGracePeriod: false
        )
        XCTAssertEqual(sut.businessAccountStatus, .active, "Expected account state to be active when the business account is active.")
    }

    func testDetermineBusinessAccountState_whenAccountInGracePeriod_shouldReturnGracePeriod() {
        let (sut, _) = makeSUT(
            hasActiveBusinessAccount: false,
            hasBusinessAccountInGracePeriod: true
        )
        XCTAssertEqual(sut.businessAccountStatus, .gracePeriod, "Expected account state to be in grace period when the business account is not active but in grace period.")
    }

    func testDetermineBusinessAccountState_whenAccountExpiredWithoutGracePeriod_shouldReturnOverdue() {
        let (sut, _) = makeSUT(
            hasActiveBusinessAccount: false,
            hasBusinessAccountInGracePeriod: false
        )
        XCTAssertEqual(sut.businessAccountStatus, .overdue, "Expected account state to be overdue when the business account is expired and not in grace period.")
    }

    func testDetermineProFlexiAccountState_whenAccountIsActive_shouldReturnActive() {
        let (sut, _) = makeSUT(hasActiveProFlexiAccount: true)
        XCTAssertEqual(sut.proFlexiAccountStatus, .active, "Expected Pro Flexi account state to be active when the account is active.")
    }

    func testDetermineProFlexiAccountState_whenAccountExpired_shouldReturnOverdue() {
        let (sut, _) = makeSUT(hasActiveProFlexiAccount: false)
        XCTAssertEqual(sut.proFlexiAccountStatus, .overdue, "Expected Pro Flexi account state to be overdue when the account is expired.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        accountType: AccountTypeEntity = .free,
        currentSubscription: AccountSubscriptionEntity? = nil,
        email: String = "test@email.com",
        smsState: SMSStateEntity = .notAllowed,
        isMasterBusinessAccount: Bool = false,
        multiFactorAuthCheckResult: Bool = false,
        multiFactorAuthCheckDelay: TimeInterval = 0,
        isStandardProAccount: Bool = false,
        isBilledProPlan: Bool = false,
        hasMultipleBilledProPlan: Bool = false,
        hasActiveBusinessAccount: Bool = false,
        hasActiveProFlexiAccount: Bool = false,
        tracker: some AnalyticsTracking = MockTracker(),
        hasBusinessAccountInGracePeriod: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ProfileViewModel, router: MockProfileViewRouter) {
        let currentAccountDetails = AccountDetailsEntity.build(proLevel: accountType)
        let accountPlan = PlanEntity(type: accountType)
        let accountUseCase = MockAccountUseCase(
            isBilledProPlan: isBilledProPlan,
            hasMultipleBilledProPlan: hasMultipleBilledProPlan,
            isStandardProAccount: isStandardProAccount,
            currentAccountDetails: currentAccountDetails,
            email: email,
            isMasterBusinessAccount: isMasterBusinessAccount,
            smsState: smsState,
            multiFactorAuthCheckResult: multiFactorAuthCheckResult,
            multiFactorAuthCheckDelay: 1.0,
            hasBusinessAccountInGracePeriod: hasBusinessAccountInGracePeriod,
            accountPlan: accountPlan,
            currentSubscription: currentSubscription,
            hasActiveBusinessAccount: hasActiveBusinessAccount,
            hasActiveProFlexiAccount: hasActiveProFlexiAccount
        )
        let router = MockProfileViewRouter()
        
        return (
            ProfileViewModel(
                accountUseCase: accountUseCase,
                achievementUseCase: MockAchievementUseCase(),
                tracker: tracker,
                router: router
            ),
            router
        )
    }
    
    private func receivedSectionDataSource(
        from sut: ProfileViewModel,
        after action: ProfileAction
    ) -> ProfileViewModel.SectionCellDataSource? {
        
        let expectation = XCTestExpectation(description: "Expected default set of sections and cell states")
        var result: ProfileViewModel.SectionCellDataSource?
        sut.sectionCellsPublisher
            .first()
            .sink { sectionDataSource in
                result = sectionDataSource
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.dispatch(action)
        wait(for: [expectation], timeout: 1)
        return result
    }
    
    private func testSectionCellsForAccountType(
        _ accountType: AccountTypeEntity,
        isPlanHidden: Bool = true,
        isSmsAllowed: Bool = false,
        isMasterBusinessAccount: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let standardProAccounts: [AccountTypeEntity] = [.lite, .proI, .proII, .proIII]
        let isSubscriptionHidden = !standardProAccounts.contains(accountType)
        let expectedSections = ProfileViewModel.SectionCellDataSource(
            sectionOrder: sectionsOrder(
                isPlanHidden: isPlanHidden,
                isSubscriptionHidden: isSubscriptionHidden
            ),
            sectionRows: sectionRows(
                isPlanHidden: isPlanHidden,
                isSubscriptionHidden: isSubscriptionHidden,
                isSmsAllowed: isSmsAllowed,
                isBusiness: accountType == .business,
                isMasterBusinessAccount: isMasterBusinessAccount
            )
        )
        let (sut, _) = makeSUT(
            accountType: accountType,
            isMasterBusinessAccount: isMasterBusinessAccount,
            isStandardProAccount: standardProAccounts.contains(accountType),
            isBilledProPlan: true
        )
        let result = self.receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        XCTAssertEqual(result, expectedSections, file: file, line: line)
    }
    
    private func sectionsOrder(
        isPlanHidden: Bool = true,
        isSubscriptionHidden: Bool = true
    ) -> [ProfileSection] {
        var sections: [ProfileSection] = isPlanHidden ? [.profile, .security, .session]: [.profile, .security, .plan, .session]
        
        if !isSubscriptionHidden {
            sections.append(.subscription)
        }
        
        return sections
    }
    
    private func sectionRows(
        isPlanHidden: Bool = true,
        isSubscriptionHidden: Bool = true,
        isSmsAllowed: Bool = false,
        isBusiness: Bool = false,
        isMasterBusinessAccount: Bool = false
    ) -> [ProfileSection: [ProfileSectionRow]] {
        let profileRows: [ProfileSectionRow] = isBusiness && !isMasterBusinessAccount ?
            [.changePhoto, .changePassword(isLoading: false)] :
            [.changeName, .changePhoto, .changeEmail(isLoading: false), .changePassword(isLoading: false)]
        
        var sections: [ProfileSection: [ProfileSectionRow]]
        
        if isPlanHidden {
            sections = [
                .profile: isSmsAllowed ? profileRows + [.phoneNumber] : profileRows,
                .security: [.recoveryKey],
                .session: [.logout]
            ]
        } else {
            sections = [
                .profile: isSmsAllowed ? profileRows + [.phoneNumber] : profileRows,
                .security: [.recoveryKey],
                .plan: isBusiness ? [.upgrade, .role] : [.upgrade],
                .session: [.logout]
            ]
        }
        
        if !isSubscriptionHidden {
            sections[.subscription] = [.cancelSubscription]
        }
        
        return sections
    }
    
    private func testPlanSectionVisibility(
        accountType: AccountTypeEntity,
        isMasterBusinessAccount: Bool = false,
        shouldBeShown: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (sut, _) = makeSUT(
            accountType: accountType,
            isMasterBusinessAccount: isMasterBusinessAccount,
            isStandardProAccount: true
        )
        sut.dispatch(.onViewDidLoad)

        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        let containsPlanSection = result?.sectionOrder.contains(.plan) ?? false
        XCTAssertEqual(containsPlanSection, shouldBeShown, "Plan section visibility does not match expectation for account type \(accountType)", file: file, line: line)
    }

    private func testSubscriptionSectionVisibility(
        isStandardProAccount: Bool = false,
        isBilledProPlan: Bool = false,
        hasMultipleBilledProPlan: Bool = false,
        shouldBeShown: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let (sut, _) = makeSUT(
            isStandardProAccount: isStandardProAccount,
            isBilledProPlan: isBilledProPlan,
            hasMultipleBilledProPlan: hasMultipleBilledProPlan
        )
        sut.dispatch(.onViewDidLoad)

        let result = receivedSectionDataSource(from: sut, after: .onViewDidLoad)
        let containsSubscriptionSection = result?.sectionOrder.contains(.subscription) ?? false
        XCTAssertEqual(containsSubscriptionSection, shouldBeShown, "Subscription section visibility does not match expectation for standard pro account state \(isStandardProAccount)", file: file, line: line)
    }
    
    private func assertActionTracker(action: ProfileAction, expectedEventIdentifiers: [any EventIdentifier]) {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        
        sut.dispatch(action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: expectedEventIdentifiers
        )
    }
}
