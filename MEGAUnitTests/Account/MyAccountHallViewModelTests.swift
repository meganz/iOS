import Combine
import DeviceCenter
import DeviceCenterMocks
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import XCTest

final class MyAccountHallViewModelTests: XCTestCase {

    @MainActor
    func testOnViewAppear_shouldReloadUIContent() {
        let (sut, _) = makeSUT()
        test(viewModel: sut,
             actions: [MyAccountHallAction.reloadUI],
             expectedCommands: [.reloadUIContent])
    }
    
    @MainActor
    func testLoadPlanList_shouldCallConfigPlanDisplay() async {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }

        sut.dispatch(.load(.planList))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(commands, [.configPlanDisplay])
    }
    
    @MainActor
    func testLoadContentCounts_shouldReloadCounts() async {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }

        sut.dispatch(.load(.contentCounts))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(commands, [.reloadCounts])
    }
    
    @MainActor
    func testLoadAccountDetails_shouldLoadAccountDetails() async {
        let mockAccountUseCase = MockAccountUseCase(
            accountDetailsResult: .success(AccountDetailsEntity.random)
        )
        let (sut, _) = makeSUT(accountUseCase: mockAccountUseCase)
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.load(.accountDetails))
        await sut.loadContentTask?.value
        
        XCTAssertEqual(mockAccountUseCase.refreshAccountDetails_calledCount, 1)
        XCTAssertEqual(mockAccountUseCase.refreshAccountDetailsWithMonitoringUpdate_calledCount, 0)
        XCTAssertEqual(commands, [.configPlanDisplay, .reloadStorage])
    }

    @MainActor
    func testisAccountUpdating_whenMonitoringRefreshAccountAndNotSubmittingReceipt_shouldReturnTrue() async {
        await assertIsAccountUpdating(isMonitoringRefreshAccount: true, isSubmittingReceipt: false, expectedIsAccountUpdating: true)
    }
    
    @MainActor
    func testisAccountUpdating_whenNotMonitoringRefreshAccountButSubmittingReceipt_shouldReturnTrue() async {
        await assertIsAccountUpdating(isMonitoringRefreshAccount: false, isSubmittingReceipt: true, expectedIsAccountUpdating: true)
    }
    
    @MainActor
    func testisAccountUpdating_whenNotMonitoringRefreshAccountAndNotSubmittingReceipt_shouldReturnFalse() async {
        await assertIsAccountUpdating(isMonitoringRefreshAccount: false, isSubmittingReceipt: false, expectedIsAccountUpdating: false)
    }
        
    @MainActor
    func assertIsAccountUpdating(
        isMonitoringRefreshAccount: Bool = false,
        isSubmittingReceipt: Bool = false,
        expectedIsAccountUpdating: Bool
    ) async {
        let mockAccountUseCase = MockAccountUseCase(
            accountDetailsResult: .success(AccountDetailsEntity.random),
            isMonitoringRefreshAccount: isMonitoringRefreshAccount
        )
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(
            isSubmittingReceiptAfterPurchase: isSubmittingReceipt
        )
        let (sut, _) = makeSUT(accountUseCase: mockAccountUseCase, purchaseUseCase: mockPurchaseUseCase)
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.load(.accountDetails))
        await sut.loadContentTask?.value

        XCTAssertEqual(sut.isAccountUpdating, expectedIsAccountUpdating)
    }

    @MainActor
    func testSubmitReceiptResultPublisher_whenSuccessResult_shouldEndMonitoringAndUpdateAccountDetails() async {
        await assertSubmitReceiptResultPublisher(
            submitResult: .success,
            accountDetailsResult: .success(AccountDetailsEntity.random),
            isExpectationInverted: false,
            expectedRefreshAccountAndMonitorCallCount: 1,
            expectedEndMonitoringCallCount: 1
        )
    }
    
    @MainActor
    func testSubmitReceiptResultPublisher_whenFailedResult_shouldDoNothing() async {
        await assertSubmitReceiptResultPublisher(
            submitResult: .failure(.init(errorCode: -11, errorMessage: nil)),
            isExpectationInverted: true,
            expectedRefreshAccountAndMonitorCallCount: 0,
            expectedEndMonitoringCallCount: 0
        )
    }
    
    @MainActor
    func assertSubmitReceiptResultPublisher(
        submitResult: Result<Void, AccountPlanErrorEntity>,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        isExpectationInverted: Bool,
        expectedRefreshAccountAndMonitorCallCount: Int,
        expectedEndMonitoringCallCount: Int
    ) async {
        let resultPublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
        let purchaseUseCase = MockAccountPlanPurchaseUseCase(submitReceiptResultPublisher: resultPublisher)
        let accountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let (sut, _) = makeSUT(accountUseCase: accountUseCase, purchaseUseCase: purchaseUseCase)
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.viewDidLoad)
     
        let exp = expectation(description: "Receive currentPlanName from accountDetail refresh")
        exp.isInverted = isExpectationInverted
        let cancellable = sut.$currentPlanName
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        resultPublisher.send(submitResult)
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(purchaseUseCase.endMonitoringPurchaseReceiptCalled, expectedEndMonitoringCallCount)
        XCTAssertEqual(accountUseCase.refreshAccountDetailsWithMonitoringUpdate_calledCount, expectedRefreshAccountAndMonitorCallCount)
        XCTAssertEqual(accountUseCase.refreshAccountDetails_calledCount, 0)
        cancellable.cancel()
    }
    
    @MainActor
    func testMonitorSubmitReceiptAfterPurchase_whenReceivedTrue_shouldUpdateActivityIndicatorDisplay() async {
        await assertMonitorSubmitReceiptAfterPurchase(isMonitor: true, expectedIsAccountUpdating: true)
    }
    
    @MainActor
    func testMonitorSubmitReceiptAfterPurchase_whenReceivedFalse_shouldKeepIsAccountUpdatingValue() async {
        let currentIsAccountUpdating = Bool.random()
        await assertMonitorSubmitReceiptAfterPurchase(
            isMonitor: false,
            currentIsAccountUpdating: currentIsAccountUpdating,
            expectedIsAccountUpdating: currentIsAccountUpdating
        )
    }
    
    @MainActor
    private func assertMonitorSubmitReceiptAfterPurchase(
        isMonitor: Bool,
        currentIsAccountUpdating: Bool = Bool.random(),
        expectedIsAccountUpdating: Bool
    ) async {
        let monitorStatusSourcePublisher = PassthroughSubject<Bool, Never>()
        let (sut, _) = makeSUT(
            purchaseUseCase: MockAccountPlanPurchaseUseCase(monitorSubmitReceiptPublisher: monitorStatusSourcePublisher.eraseToAnyPublisher())
        )
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.viewDidLoad)
        sut.isAccountUpdating = currentIsAccountUpdating
        
        let exp = expectation(description: "Receive monitorSubmitReceiptAfterPurchase status")
        exp.isInverted = !isMonitor
        let cancellable = sut.$isAccountUpdating
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        monitorStatusSourcePublisher.send(isMonitor)
        await fulfillment(of: [exp], timeout: 1.0)
        
        let expectedCommands: [MyAccountHallViewModel.Command] = isMonitor ? [.reloadStorage] : []
        XCTAssertEqual(sut.isAccountUpdating, expectedIsAccountUpdating)
        XCTAssertEqual(commands, expectedCommands)
        cancellable.cancel()
    }
    
    @MainActor
    func testMonitorRefreshAccount_whenStatusIsReceived_shouldUpdateActivityIndicatorDisplay() async {
        let monitorStatusSourcePublisher = PassthroughSubject<Bool, Never>()
        let (sut, _) = makeSUT(
            accountUseCase: MockAccountUseCase(monitorRefreshAccountPublisher: monitorStatusSourcePublisher.eraseToAnyPublisher())
        )
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.viewDidLoad)

        let exp = expectation(description: "Receive monitorRefreshAccount status")
        let cancellable = sut.$isAccountUpdating
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        let expectedStatus = Bool.random()
        monitorStatusSourcePublisher.send(expectedStatus)
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.isAccountUpdating, expectedStatus, "Should set expected status to hide/show activity indicator on Current plan row")
        XCTAssertEqual(commands, [.reloadStorage], "Should call reloadStorage to hide/show activity indicator on Storage row")
        cancellable.cancel()
    }
    
    @MainActor
    func testViewWillAppear_shouldStartAccountUpdatesMonitoring() {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.viewWillAppear)
        
        XCTAssertNotNil(sut.onAccountRequestFinishUpdatesTask)
        XCTAssertNotNil(sut.onUserAlertsUpdatesTask)
        XCTAssertNotNil(sut.onContactRequestsUpdatesTask)
        XCTAssertEqual(commands, [])
    }
    
    @MainActor
    func testViewWillDisappear_shouldStopAccountUpdatesMonitoring() {
        let (sut, _) = makeSUT()
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.viewWillDisappear)
        
        XCTAssertNil(sut.onAccountRequestFinishUpdatesTask)
        XCTAssertNil(sut.onUserAlertsUpdatesTask)
        XCTAssertNil(sut.onContactRequestsUpdatesTask)
        XCTAssertEqual(commands, [])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_accountDetailsRequest_shouldHandleRequest() {
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)
        )

        XCTAssertEqual(commands, [.reloadUIContent])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_getAttrUserRequestWithFile_shouldHandleRequest() {
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .getAttrUser, file: "Test file", userAttribute: nil, email: nil)
        )
        
        XCTAssertEqual(commands, [.setUserAvatar])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_getAttrUserRequestWithNoFile_shouldHandleRequest() {
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: nil, email: nil),
            isExpectationInverted: true
        )
        
        XCTAssertEqual(commands, [])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_getAttrUserRequestWithUserAttr_shouldHandleRequest() {
        let userAttribute = [UserAttributeEntity.firstName, UserAttributeEntity.lastName].randomElement() ?? .firstName
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: userAttribute, email: nil)
        )
        
        XCTAssertEqual(commands, [.setName])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_getAttrUserRequestWithFileAndUserAttr_shouldHandleRequest() {
        let userAttribute = [UserAttributeEntity.firstName, UserAttributeEntity.lastName].randomElement() ?? .firstName
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .getAttrUser, file: "Test file", userAttribute: userAttribute, email: nil),
            expectedCommandCount: 2
        )
        
        XCTAssertEqual(commands, [.setUserAvatar, .setName])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onAccountRequestFinish_getAttrUserRequestWithNoFileAndNoUserAttr_shouldNotCallAnyCommand() {
        let commands = assertAccountRequestFinishCommands(
            request: AccountRequestEntity(type: .getAttrUser, file: nil, userAttribute: nil, email: nil),
            isExpectationInverted: true
        )
        
        XCTAssertEqual(commands, [])
    }
    
    @MainActor
    private func assertAccountRequestFinishCommands(
        request: AccountRequestEntity,
        expectedCommandCount: Int = 1,
        isExpectationInverted: Bool = false
    ) -> [MyAccountHallViewModel.Command] {
        let (stream, continuation) = AsyncStream<Result<AccountRequestEntity, any Error>>.makeStream()
        let (sut, _) = makeSUT(onAccountRequestFinish: stream.eraseToAnyAsyncSequence())
        
        let expectation = expectation(description: #function)
        expectation.expectedFulfillmentCount = expectedCommandCount
        expectation.isInverted = isExpectationInverted
        
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
            expectation.fulfill()
        }
        sut.dispatch(.viewWillAppear)
        
        continuation.yield(.success(request))
        continuation.finish()
        
        wait(for: [expectation], timeout: 1)
        
        return commands
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onUserAlertsUpdates_shouldUpdateAlertCounts() {
        let (stream, continuation) = AsyncStream<[UserAlertEntity]>.makeStream()
        let (sut, _) = makeSUT(onUserAlertsUpdates: stream.eraseToAnyAsyncSequence())
        
        let expectation = expectation(description: #function)
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
            expectation.fulfill()
        }
        sut.dispatch(.viewWillAppear)
        
        // Set lower user alert count
        sut.$relevantUnseenUserAlertsCount.mutate { currentValue in
            currentValue = UInt.random(in: 1...5)
        }
        
        let alerts = generateRandomUserAlerts(count: Int.random(in: 6...10))
        continuation.yield(alerts)
        continuation.finish()
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(sut.relevantUnseenUserAlertsCount, UInt(alerts.count))
        XCTAssertEqual(commands, [.reloadCounts])
    }
    
    @MainActor
    func testAccountUpdatesMonitoring_onContactRequestsUpdates_shouldUpdateContactRequestCounts() {
        let (stream, continuation) = AsyncStream<[ContactRequestEntity]>.makeStream()
        let (sut, _) = makeSUT(onContactRequestsUpdates: stream.eraseToAnyAsyncSequence())
        
        let expectation = expectation(description: #function)
        var commands = [MyAccountHallViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
            expectation.fulfill()
        }
        sut.dispatch(.viewWillAppear)
        
        // Set lower contact request count
        sut.incomingContactRequestsCount = Int.random(in: 1...5)
        
        let requests = generateRandomContactRequests(count: Int.random(in: 6...10))
        continuation.yield(requests)
        continuation.finish()
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(sut.incomingContactRequestsCount, requests.count)
        XCTAssertEqual(commands, [.reloadCounts])
    }

    @MainActor
    func testInitAccountDetails_shouldHaveCorrectDetails() {
        let expectedAccountDetails = AccountDetailsEntity.random
        let (sut, _) = makeSUT(currentAccountDetails: expectedAccountDetails)
    
        XCTAssertEqual(sut.accountDetails, expectedAccountDetails)
    }
    
    @MainActor
    func testArePromosAvailable_whenNotificationsEnabled_shouldReturnTrue() async throws {
        let (sut, _) = makeSUT(
            enabledNotifications: [NotificationIDEntity(1), NotificationIDEntity(2), NotificationIDEntity(3)]
        )
        
        let result = await loadPromosAndGetAvailability(for: sut)
        XCTAssertTrue(result, "Promos should be available when notifications are enabled and the notification center feature flag is true.")
    }
    
    @MainActor
    func testArePromosAvailable_whenNoEnabledNotifications_shouldReturnFalse() async throws {
        let (sut, _) = makeSUT(enabledNotifications: [])
        
        let result = await loadPromosAndGetAvailability(for: sut)
        XCTAssertFalse(result, "Promos should not be available when notifications are not enabled, even if the notification center feature flag is true.")
    }

    @MainActor
    func testIsMasterBusinessAccount_shouldBeTrue() {
        let (sut, _) = makeSUT(isMasterBusinessAccount: true)
        XCTAssertTrue(sut.isMasterBusinessAccount)
    }
    
    @MainActor
    func testIsMasterBusinessAccount_shouldBeFalse() {
        let (sut, _) = makeSUT(isMasterBusinessAccount: false)
        XCTAssertFalse(sut.isMasterBusinessAccount)
    }
    
    @MainActor
    func testDidTapUpgradeButton_shouldShowUpgradeView() {
        let (sut, _) = makeSUT()
        
        test(viewModel: sut, actions: [MyAccountHallAction.didTapUpgradeButton], expectedCommands: [])
    }
    
    @MainActor
    func testDidTapDeviceCenterButton_whenButtonIsTapped_navigatesToDeviceCenter() {
        let (sut, router) = makeSUT()
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        XCTAssertEqual(router.navigateToDeviceCenter_calledTimes, 1)
    }
    
    @MainActor
    func testDidTapCameraUploadsAction_whenCameraUploadActionTapped_callsRouterOnce() {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.cameraUploadActionTapped({})
        
        XCTAssertEqual(
            router.didTapCameraUploadsAction_calledTimes, 1, "Camera upload action should have called the router once"
        )
    }
    
    @MainActor
    func testDidTapRenameAction_whenRenameActionTapped_callsRouterOnce() {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.renameActionTapped(
            RenameActionEntity(
                oldName: "",
                otherNamesInContext: [],
                actionType: .device(deviceId: "", maxCharacters: 32),
                alertTitles: [:],
                alertMessage: [:],
                alertPlaceholder: "",
                renamingFinished: {}
            )
        )
        
        XCTAssertEqual(
            router.didTapRenameAction_calledTimes, 1, "Rename node action should have called the router once"
        )
    }
    
    @MainActor
    func testDidTapShowIn_whenShowInActionTapped_callsRouterOnce() async throws {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.showInTapped(
            NavigateToContentActionEntity(
                type: .showInBackups,
                node: MockNode(handle: 1).toNodeEntity(),
                error: nil
            )
        )
        
        XCTAssertEqual(
            router.didTapShowInAction_calledTimes, 1, "Show in action should have called the router once"
        )
    }
    
    @MainActor
    func testDidTapInfoAction_whenInfoActionTapped_callsRouterOnce() async throws {
        let deviceCenterBridge = DeviceCenterBridge()
        let (sut, router) = makeSUT(deviceCenterBridge: deviceCenterBridge)
        
        test(viewModel: sut,
             actions: [MyAccountHallAction.didTapDeviceCenterButton],
             expectedCommands: [])
        
        deviceCenterBridge.infoActionTapped(
            ResourceInfoModel(
                icon: Image(.black),
                name: "",
                counter: ResourceCounter.emptyCounter
            )
        )
        
        XCTAssertEqual(
            router.didTapInfoAction_calledTimes, 1, "Info action should have called the router once"
        )
    }
    
    @MainActor
    private func loadPromosAndGetAvailability(for sut: MyAccountHallViewModel) async -> Bool {
        sut.dispatch(.load(.promos))
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        return sut.arePromosAvailable
    }
    
    @MainActor
    func testShowPlanRow_businessAccount_shouldBeFalse() {
        let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: .business))
        
        XCTAssertFalse(sut.showPlanRow)
    }
    
    @MainActor
    func testShowPlanRow_proFlexiAccount_shouldBeFalse() {
        let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: .proFlexi))
        
        XCTAssertFalse(sut.showPlanRow)
    }
    
    @MainActor
    func testShowPlanRow_freeOrProAccount_shouldBeTrue() {
        let accountTypes: [AccountTypeEntity] = [.free, .proI, .proII, .proIII]
        accountTypes.enumerated().forEach { (index, accountType) in
            let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: accountType))
            
            XCTAssertTrue(sut.showPlanRow, "failed at index: \(index) for accountType: \(accountType)")
        }
    }
    
    @MainActor
    func testCalculateCellHeight_planSection_showPlanRowIsTrue_shouldNotBeZero() {
        let accountTypes: [AccountTypeEntity] = [.free, .proI, .proII, .proIII]
        let indexPath = IndexPath(row: MyAccountMegaSection.plan.rawValue,
                                  section: MyAccountSection.mega.rawValue)
        
        accountTypes.enumerated().forEach { (index, accountType) in
            let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: accountType))
            
            XCTAssertNotEqual(sut.calculateCellHeight(at: indexPath), 0, "failed at index: \(index) for accountType: \(accountType)")
        }
    }
    
    @MainActor
    func testCalculateCellHeight_planSection_showPlanRowIsFalse_shouldBeZero() {
        let accountTypes: [AccountTypeEntity] = [.proFlexi, .business]
        let indexPath = IndexPath(row: MyAccountMegaSection.plan.rawValue,
                                  section: MyAccountSection.mega.rawValue)

        accountTypes.enumerated().forEach { (index, accountType) in
            let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.build(proLevel: accountType))
            
            XCTAssertEqual(sut.calculateCellHeight(at: indexPath), 0, "failed at index: \(index) for accountType: \(accountType)")
        }
    }
    
    @MainActor
    func testCalculateCellHeight_achievementSection_isAchievementEnabledTrue_shouldNotBeZero() {
        let indexPath = IndexPath(row: MyAccountMegaSection.achievements.rawValue,
                                  section: MyAccountSection.mega.rawValue)
        
        let (sut, _) = makeSUT(isAchievementsEnabled: true)
        
        XCTAssertNotEqual(sut.calculateCellHeight(at: indexPath), 0)
    }
    
    @MainActor
    func testCalculateCellHeight_achievementSection_isAchievementEnabledFalse_shouldBeZero() {
        let indexPath = IndexPath(row: MyAccountMegaSection.achievements.rawValue,
                                  section: MyAccountSection.mega.rawValue)
        
        let (sut, _) = makeSUT(isAchievementsEnabled: false)
        
        XCTAssertEqual(sut.calculateCellHeight(at: indexPath), 0)
    }
    
    @MainActor
    func testCalculateCellHeight_myAccountSection_shouldNotBeZero() {
        let (sut, _) = makeSUT(currentAccountDetails: AccountDetailsEntity.random)
        let indexPath = IndexPath(row: MyAccountMegaSection.myAccount.rawValue,
                                  section: MyAccountSection.mega.rawValue)
        
        XCTAssertNotEqual(sut.calculateCellHeight(at: indexPath), 0)
    }
    
    @MainActor
    func testDidTapMyAccountButton_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapMyAccountButton,
            expectedEvent: MyAccountProfileNavigationItemEvent()
        )
    }
    
    @MainActor
    func testDidTapAccountHeader_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapAccountHeader,
            expectedEvent: AccountScreenHeaderTappedEvent()
        )
    }
    
    @MainActor
    func testViewDidLoad_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .viewDidLoad,
            expectedEvent: AccountScreenEvent()
        )
    }
    
    @MainActor
    func testViewDidTapUpgradeButton_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapUpgradeButton,
            expectedEvent: UpgradeMyAccountEvent()
        )
    }
    
    @MainActor
    func testDidTapNotificationCentre_shouldTrackNotificationCentreButtonPressedEvent() {
        trackAnalyticsEventTest(
            action: .didTapNotificationCentre,
            expectedEvent: NotificationsEntryButtonPressedEvent()
        )
    }
    
    @MainActor
    func testUnreadNotificationCount_shouldTrackNotificationCenterEvents() async {
        await validateTrackingEvent(
            unreadNotificationIDs: [NotificationIDEntity(1)],
            expectedEvent: AccountNotificationCentreDisplayedWithUnreadNotificationsEvent()
        )
        
        await validateTrackingEvent(
            unreadNotificationIDs: [],
            expectedEvent: AccountNotificationCentreDisplayedWithNoUnreadNotificationsEvent()
        )
    }
    
    @MainActor
    func testTransferUsed_shouldReturnCorrectValue() {
        let expectedTransferUsed: Int64 = 5000
        let accountDetails = AccountDetailsEntity.build(transferUsed: expectedTransferUsed)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertEqual(sut.transferUsed, expectedTransferUsed)
    }
    
    @MainActor
    func testTransferUsed_whenAccountDetailsNil_shouldReturnZero() {
        let (sut, _) = makeSUT(currentAccountDetails: nil)
        
        XCTAssertEqual(sut.transferUsed, 0)
    }
    
    @MainActor
    func testTransferMax_shouldReturnCorrectValue() {
        let expectedTransferMax: Int64 = 10000
        let accountDetails = AccountDetailsEntity.build(transferMax: expectedTransferMax)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertEqual(sut.transferMax, expectedTransferMax)
    }
    
    @MainActor
    func testTransferMax_whenAccountDetailsNil_shouldReturnZero() {
        let (sut, _) = makeSUT(currentAccountDetails: nil)
        
        XCTAssertEqual(sut.transferMax, 0)
    }
    
    @MainActor
    func testStorageUsed_shouldReturnCorrectValue() {
        let expectedStorageUsed: Int64 = 7500
        let accountDetails = AccountDetailsEntity.build(storageUsed: expectedStorageUsed)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertEqual(sut.storageUsed, expectedStorageUsed)
    }
    
    @MainActor
    func testStorageUsed_whenAccountDetailsNil_shouldReturnZero() {
        let (sut, _) = makeSUT(currentAccountDetails: nil)
        
        XCTAssertEqual(sut.storageUsed, 0)
    }
    
    @MainActor
    func testStorageMax_shouldReturnCorrectValue() {
        let expectedStorageMax: Int64 = 20000
        let accountDetails = AccountDetailsEntity.build(storageMax: expectedStorageMax)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertEqual(sut.storageMax, expectedStorageMax)
    }
    
    @MainActor
    func testStorageMax_whenAccountDetailsNil_shouldReturnZero() {
        let (sut, _) = makeSUT(currentAccountDetails: nil)
        
        XCTAssertEqual(sut.storageMax, 0)
    }
    
    @MainActor
    func testIsBusinessAccount_shouldBeTrue() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .business)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertTrue(sut.isBusinessAccount)
    }
    
    @MainActor
    func testIsBusinessAccount_shouldBeFalse() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .proI)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertFalse(sut.isBusinessAccount)
    }
    
    @MainActor
    func testIsProFlexiAccount_shouldBeTrue() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .proFlexi)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertTrue(sut.isProFlexiAccount)
    }
    
    @MainActor
    func testIsProFlexiAccount_shouldBeFalse() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .proI)
        let (sut, _) = makeSUT(currentAccountDetails: accountDetails)
        
        XCTAssertFalse(sut.isProFlexiAccount)
    }
    
    @MainActor
    func testRubbishBinFormattedStorageUsed_shouldReturnFormattedString() {
        let expectedRubbishBinStorageUsed: Int64 = 2048
        let expectedFormattedString = "2 KB"
        
        let (sut, _) = makeSUT(rubbishBinStorage: expectedRubbishBinStorageUsed)
        
        XCTAssertEqual(sut.rubbishBinFormattedStorageUsed, expectedFormattedString)
    }
    
    @MainActor func testNavigateToProfile_shouldCallNavigateToProfileOnRouter() {
        let (sut, router) = makeSUT()
        
        sut.dispatch(.navigateToProfile)
        
        XCTAssertEqual(router.navigateToProfile_calledTimes, 1, "navigateToProfile should be called once")
    }
    
    @MainActor func testNavigateToUsage_shouldCallNavigateToUsageOnRouter() {
        let (sut, router) = makeSUT()
        
        sut.dispatch(.navigateToUsage)
        
        XCTAssertEqual(router.navigateToUsage_calledTimes, 1, "navigateToUsage should be called once")
    }
    
    @MainActor func testNavigateToSettings_shouldCallNavigateToSettingsOnRouter() {
        let (sut, router) = makeSUT()
        
        sut.dispatch(.navigateToSettings)
        
        XCTAssertEqual(router.navigateToSettings_calledTimes, 1, "navigateToSettings should be called once")
    }
    
    @MainActor func testNavigateToNotificationCentre_shouldCallNavigateToNotificationCentreOnRouter() {
        let (sut, router) = makeSUT()
        
        sut.dispatch(.didTapNotificationCentre)
        
        XCTAssertEqual(router.navigateToNotificationCentre_calledTimes, 1, "navigateToNotificationCentre should be called once")
    }
    
    @MainActor
    private func makeSUT(
        isMasterBusinessAccount: Bool = false,
        isAchievementsEnabled: Bool = false,
        enabledNotifications: [NotificationIDEntity] = [],
        unreadNotificationIDs: [NotificationIDEntity] = [],
        currentAccountDetails: AccountDetailsEntity? = nil,
        deviceCenterBridge: DeviceCenterBridge = DeviceCenterBridge(),
        tracker: some AnalyticsTracking = MockTracker(),
        rubbishBinStorage: Int64 = 0,
        onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        notificationCenter: NotificationCenter = NotificationCenter(),
        accountUseCase: ((any AccountUseCaseProtocol)?) = nil,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol = MockAccountPlanPurchaseUseCase()
    ) -> (MyAccountHallViewModel, MockMyAccountHallRouter) {
        let myAccountHallUseCase = MockMyAccountHallUseCase(
            currentAccountDetails: currentAccountDetails ?? AccountDetailsEntity.random,
            isMasterBusinessAccount: isMasterBusinessAccount,
            isAchievementsEnabled: isAchievementsEnabled,
            onAccountRequestFinish: onAccountRequestFinish,
            onUserAlertsUpdates: onUserAlertsUpdates,
            onContactRequestsUpdates: onContactRequestsUpdates
        )
        
        let accountUseCase = accountUseCase ?? MockAccountUseCase(rubbishBinStorage: rubbishBinStorage)
        let shareUseCase = MockShareUseCase()
        let notificationUseCase = MockNotificationUseCase(
            enabledNotifications: enabledNotifications,
            unreadNotificationIDs: unreadNotificationIDs
        )
        let router = MockMyAccountHallRouter()
        
        return (
            MyAccountHallViewModel(
                myAccountHallUseCase: myAccountHallUseCase,
                accountUseCase: accountUseCase,
                purchaseUseCase: purchaseUseCase,
                shareUseCase: shareUseCase,
                notificationsUseCase: notificationUseCase,
                deviceCenterBridge: deviceCenterBridge,
                tracker: tracker,
                router: router,
                notificationCenter: notificationCenter
            ), router
        )
    }
    
    @MainActor
    private func trackAnalyticsEventTest(
        action: MyAccountHallAction,
        expectedEvent: any EventIdentifier
    ) {
        let mockTracker = MockTracker()
        let (sut, _) = makeSUT(tracker: mockTracker)
        
        sut.dispatch(action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
    
    private func generateRandomUserAlerts(count: Int) -> [UserAlertEntity] {
        guard count > 1 else { return [] }
        
        var list: [UserAlertEntity] = []
        (1...count).forEach { _ in
            list.append(UserAlertEntity.random)
        }
        return list
    }
    
    private func generateRandomContactRequests(count: Int) -> [ContactRequestEntity] {
        guard count > 1 else { return [] }
        
        var list: [ContactRequestEntity] = []
        (1...count).forEach { _ in
            list.append(ContactRequestEntity.random)
        }
        return list
    }
    
    @MainActor
    private func validateTrackingEvent(
        unreadNotificationIDs: [NotificationIDEntity],
        expectedEvent: any EventIdentifier
    ) async {
        let mockTracker = MockTracker()
        let (sut, _) = makeSUT(
            unreadNotificationIDs: unreadNotificationIDs,
            tracker: mockTracker
        )
        
        sut.dispatch(.load(.contentCounts))
        await sut.loadContentTask?.value
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
}
