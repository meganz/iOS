import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGATest
import XCTest

final class ChatRoomsListViewModelTests: XCTestCase {
    var subscription: AnyCancellable?
    let chatsListMock = [
        ChatListItemEntity(chatId: 1, title: "Chat1"),
        ChatListItemEntity(chatId: 3, title: "Chat2"),
        ChatListItemEntity(chatId: 67, title: "Chat3")
    ]
    let meetingsListMock = [
        ChatListItemEntity(chatId: 11, title: "Meeting 1", meeting: true),
        ChatListItemEntity(chatId: 14, title: "Meeting 2", meeting: true),
        ChatListItemEntity(chatId: 51, title: "Meeting 3", meeting: true)
    ]

    @MainActor
    func test_remoteChatStatusChange() {
        let userHandle: HandleEntity = 100
        let chatUseCase = MockChatUseCase(myUserHandle: userHandle)
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, accountUseCase: MockAccountUseCase(currentUser: MEGADomain.UserEntity(handle: 100)))
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Awaiting publisher")
        
        subscription = viewModel
            .$chatStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
        
        let chatStatus = ChatStatusEntity.allCases.randomElement()!
        chatUseCase.statusChangePublisher.send((userHandle, chatStatus))
        
        waitForExpectations(timeout: 10)
        
        XCTAssert(viewModel.chatStatus == chatStatus)
        subscription = nil
    }
    
    @MainActor
    private func verifyNetworkConnectivity(isConnected: Bool) async {
        let networkUseCase = MockNetworkMonitorUseCase(
            connected: isConnected,
            connectionSequence: AsyncStream { continuation in
                continuation.yield(isConnected)
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        )
        
        let viewModel = makeChatRoomsListViewModel(networkMonitorUseCase: networkUseCase)
        
        for await connectionStatus in networkUseCase.connectionSequence {
            XCTAssertEqual(connectionStatus, networkUseCase.isConnected())
            XCTAssertEqual(viewModel.isConnectedToNetwork, connectionStatus)
            return
        }
    }
    
    @MainActor
    func testNetworkConnectivity_whenNotReachable_updatesIsConnectedToFalse() async {
        await verifyNetworkConnectivity(isConnected: false)
    }

    @MainActor
    func testNetworkConnectivity_whenReachable_updatesIsConnectedToTrue() async {
        await verifyNetworkConnectivity(isConnected: true)
    }
    
    @MainActor
    func testAction_addChatButtonTapped() {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(router: router)
        
        viewModel.addChatButtonTapped()
        
        XCTAssert(router.presentStartConversation_calledTimes == 1)
    }
    
    @MainActor
    func testSelectChatsMode_inputAsChats_viewModelsShouldMatch() {
        let mockList = chatsListMock
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList),
            chatViewMode: .meetings
        )
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Compare the past meetings")
        subscription = viewModel
            .$displayChatRooms
            .dropFirst()
            .sink { result in
                XCTAssert(mockList == result.flatMap { $0.map(\.chatListItem) })
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.chats)
        wait(for: [expectation], timeout: 6)
    }
    
    @MainActor
    func testSelectChatsMode_inputAsMeeting_viewModelsShouldMatch() {
        let mockList = meetingsListMock
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList),
            chatViewMode: .chats
        )
        viewModel.loadChatRoomsIfNeeded()
        
        let expectation = expectation(description: "Compare the past meetings")
        subscription = viewModel
            .$displayPastMeetings
            .filter { $0?.count == 3 }
            .prefix(1)
            .sink { _ in
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.meetings)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(mockList, viewModel.displayPastMeetings.flatMap { $0.map(\.chatListItem) })
    }
    
    // MARK: - Offline mode

    @MainActor
    func testNoNetworkEmptyViewState_whenDisconnectedAndOfflineModeDisabled_coversTheList() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )

        XCTAssertNotNil(viewModel.noNetworkEmptyViewState())
    }

    @MainActor
    func testNoNetworkEmptyViewState_whenDisconnectedAndOfflineModeEnabled_doesNotCoverTheList() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        XCTAssertNil(viewModel.noNetworkEmptyViewState())
    }

    @MainActor
    func testLoadChatRoomsIfNeeded_whenChatNotConnectedAndOfflineModeDisabled_doesNotLoadChats() {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: chatsListMock, currentChatConnectionStatus: .invalid),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )

        viewModel.loadChatRoomsIfNeeded()

        XCTAssertNil(viewModel.displayChatRooms)
    }

    @MainActor
    func testLoadChatRoomsIfNeeded_whenChatNotConnectedAndOfflineModeEnabled_loadsChatsOnTheDevice() async throws {
        let mockList = chatsListMock
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList, currentChatConnectionStatus: .invalid),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        let expectation = expectation(description: "Awaiting the chats stored on the device")
        subscription = viewModel
            .$displayChatRooms
            .compactMap { $0 }
            .prefix(1)
            .sink { _ in expectation.fulfill() }

        viewModel.loadChatRoomsIfNeeded()

        await fulfillment(of: [expectation], timeout: 6)
        XCTAssertEqual(mockList, viewModel.displayChatRooms.flatMap { $0.map(\.chatListItem) })
    }

    @MainActor
    func testLoadChatRoomsIfNeeded_whenMeetingsTabIsOffline_listsTheMeetingsOnTheDevice() async throws {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: meetingsListMock, currentChatConnectionStatus: .invalid),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            chatViewMode: .meetings,
            isNewOfflineModeEnabled: true
        )

        let expectation = expectation(description: "Awaiting the meetings stored on the device")
        subscription = viewModel
            .$displayPastMeetings
            .filter { $0?.count == 3 }
            .prefix(1)
            .sink { _ in expectation.fulfill() }

        viewModel.loadChatRoomsIfNeeded()

        await fulfillment(of: [expectation], timeout: 6)
        XCTAssertEqual(meetingsListMock, viewModel.displayPastMeetings.flatMap { $0.map(\.chatListItem) })
    }

    /// Offline the occurrences cannot be fetched, so a recurring meeting that only stays in the
    /// future section thanks to them falls back to the past meetings section instead of hanging
    /// the tab on the loading spinner.
    @MainActor
    func testLoadChatRoomsIfNeeded_whenMeetingsTabIsOffline_doesNotFetchUpcomingOccurrences() throws {
        let oneHourAgo = try XCTUnwrap(pastDate(bySubtractHours: 1))
        let recurringMeeting = ScheduledMeetingEntity(
            chatId: 1,
            scheduledId: 100,
            endDate: oneHourAgo,
            rules: ScheduledMeetingRulesEntity(frequency: .daily)
        )
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(
            scheduledMeetingsList: [recurringMeeting],
            upcomingOccurrences: [100: ScheduledMeetingOccurrenceEntity()]
        )
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(currentChatConnectionStatus: .invalid),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatViewMode: .meetings,
            isNewOfflineModeEnabled: true
        )

        viewModel.loadChatRoomsIfNeeded()

        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.isEmpty == false
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 5)
    }

    /// With no chats at all the offline user reaches the regular empty state, whose buttons
    /// (new chat, invite, start and schedule meeting) all need a connection. They stay on screen
    /// greyed out rather than disappearing.
    @MainActor
    func testEmptyViewState_whenOffline_disablesTheActionsRequiringAConnection() {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: []),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        let buttons = viewModel.emptyViewState()?.bottomButtons ?? []
        XCTAssertNotEqual(buttons.count, 0)
        XCTAssertEqual(buttons.filter(\.isEnabled).count, 0)
    }

    @MainActor
    func testEmptyViewState_whenOnline_enablesTheActions() {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: []),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true),
            isNewOfflineModeEnabled: true
        )

        let buttons = viewModel.emptyViewState()?.bottomButtons ?? []
        XCTAssertNotEqual(buttons.count, 0)
        XCTAssertEqual(buttons.filter { !$0.isEnabled }.count, 0)
    }

    @MainActor
    func testContactsOnMegaRow_whenOffline_isShownDisabled() async {
        let viewModel = await loadedChatsViewModel(isConnected: false)

        XCTAssertTrue(viewModel.shouldShowContactsOnMegaRow)
        XCTAssertFalse(viewModel.isContactsOnMegaRowEnabled)
    }

    @MainActor
    func testContactsOnMegaRow_whenOnline_isShownEnabled() async {
        let viewModel = await loadedChatsViewModel(isConnected: true)

        XCTAssertTrue(viewModel.shouldShowContactsOnMegaRow)
        XCTAssertTrue(viewModel.isContactsOnMegaRowEnabled)
    }

    /// Offline mode on, chats already loaded from the device, so `existMoreChatsThanNoteToSelf`
    /// is true and the connection is the only thing left driving the row's enabled state.
    @MainActor
    private func loadedChatsViewModel(isConnected: Bool) async -> ChatRoomsListViewModel {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(
                items: chatsListMock,
                currentChatConnectionStatus: isConnected ? .online : .invalid
            ),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: isConnected),
            isNewOfflineModeEnabled: true
        )

        let expectation = expectation(description: "Awaiting the loaded chats")
        subscription = viewModel
            .$displayChatRooms
            .compactMap { $0 }
            .prefix(1)
            .sink { _ in expectation.fulfill() }

        viewModel.loadChatRoomsIfNeeded()

        await fulfillment(of: [expectation], timeout: 6)
        return viewModel
    }

    /// The button is only rendered once its configuration exists, so without this it would be
    /// missing from the toolbar offline rather than greyed out.
    @MainActor
    func testLoadChatRoomsIfNeeded_whenOffline_buildsTheContextMenuConfiguration() async {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        viewModel.loadChatRoomsIfNeeded()

        let predicate = NSPredicate { _, _ in viewModel.contextMenuConfiguration != nil }
        await fulfillment(of: [expectation(for: predicate, evaluatedWith: nil)], timeout: 6)
    }

    @MainActor
    func testLoadChatRoomsIfNeeded_whenOfflineModeDisabled_leavesTheContextMenuConfigurationAlone() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )

        viewModel.loadChatRoomsIfNeeded()

        let predicate = NSPredicate { _, _ in viewModel.contextMenuConfiguration != nil }
        let unexpected = expectation(for: predicate, evaluatedWith: nil)
        unexpected.isInverted = true
        wait(for: [unexpected], timeout: 3)
    }

    @MainActor
    func testActionsRequiringConnectionEnabled_whenOffline_isFalse() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        XCTAssertFalse(viewModel.actionsRequiringConnectionEnabled)
    }

    @MainActor
    func testActionsRequiringConnectionEnabled_whenOnline_isTrue() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true),
            isNewOfflineModeEnabled: true
        )

        XCTAssertTrue(viewModel.actionsRequiringConnectionEnabled)
    }

    /// With the flag off the chat list keeps offering everything, the full page cover is what
    /// stops the user from reaching it.
    @MainActor
    func testActionsRequiringConnectionEnabled_whenOfflineModeDisabled_isTrue() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )

        XCTAssertTrue(viewModel.actionsRequiringConnectionEnabled)
    }

    @MainActor
    func testDisplayedChatStatus_whenOffline_isOfflineInsteadOfTheStalePresence() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )
        viewModel.chatStatus = .online

        XCTAssertEqual(viewModel.displayedChatStatus, .offline)
    }

    @MainActor
    func testDisplayedChatStatus_whenOnline_isThePresence() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true),
            isNewOfflineModeEnabled: true
        )
        viewModel.chatStatus = .away

        XCTAssertEqual(viewModel.displayedChatStatus, .away)
    }

    @MainActor
    func testDisplayedChatStatus_whenOfflineModeDisabled_isThePresence() {
        let viewModel = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )
        viewModel.chatStatus = .online

        XCTAssertEqual(viewModel.displayedChatStatus, .online)
    }

    @MainActor
    func testShouldShowArchivedChatsRow_whenOnline_isFalse() {
        let chatUseCase = MockChatUseCase()
        chatUseCase.archivedChatsCount = 2
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: true),
            isNewOfflineModeEnabled: true
        )

        XCTAssertFalse(viewModel.shouldShowArchivedChatsRow)
    }

    @MainActor
    func testShouldShowArchivedChatsRow_whenOfflineWithArchivedChats_isTrue() {
        let chatUseCase = MockChatUseCase()
        chatUseCase.archivedChatsCount = 2
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        XCTAssertTrue(viewModel.shouldShowArchivedChatsRow)
    }

    @MainActor
    func testShouldShowArchivedChatsRow_whenOfflineWithoutArchivedChats_isFalse() {
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: true
        )

        XCTAssertFalse(viewModel.shouldShowArchivedChatsRow)
    }

    @MainActor
    func testShouldShowArchivedChatsRow_whenOfflineModeDisabled_isFalse() {
        let chatUseCase = MockChatUseCase()
        chatUseCase.archivedChatsCount = 2
        let viewModel = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase,
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            isNewOfflineModeEnabled: false
        )

        XCTAssertFalse(viewModel.shouldShowArchivedChatsRow)
    }

    @MainActor
    func test_EmptyChatsList() {
        let viewModel = makeChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    @MainActor
    func test_ChatListWithoutViewOnScreen() {
        let viewModel = makeChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    @MainActor
    func testDisplayFutureMeetings_whenEmpty_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let yesterday = try XCTUnwrap(futureDate(byAddingDays: -1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, endDate: yesterday)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings != nil && viewModel.displayFutureMeetings != []
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 5)
    }
    
    @MainActor
    func testDisplayFutureMeetings_containsMultipleSections_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let tomorrow = try XCTUnwrap(futureDate(byAddingDays: 1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, endDate: tomorrow)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting], upcomingOccurrences: [100: ScheduledMeetingOccurrenceEntity()])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.first?.items.first?.scheduledMeeting.chatId == 1
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 10)
    }
    
    @MainActor
    func testDisplayFutureMeetings_containsScheduledMeetingWithNoOccurrence_shouldNotContainFutureMeeting() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let twoHourAgo = try XCTUnwrap(pastDate(bySubtractHours: 2))
        let oneHourAgo = try XCTUnwrap(pastDate(bySubtractHours: 1))
        let oneHourLater = try XCTUnwrap(futureDate(byAddingHours: 1))
        let scheduleMeetingWithNoOccurrence = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, startDate: twoHourAgo, endDate: oneHourAgo, rules: ScheduledMeetingRulesEntity(frequency: .daily, until: oneHourLater))
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeetingWithNoOccurrence], upcomingOccurrences: [:])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings != nil && viewModel.displayFutureMeetings != []
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 5)
    }
    
    @MainActor
    func testDisplayFutureMeetings_containsScheduledMeetingWithOneOccurrence_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let tomorrow = try XCTUnwrap(futureDate(byAddingDays: 1))
        let scheduleMeetingWithOnOccurrence = ScheduledMeetingEntity(chatId: 1, scheduledId: 100, endDate: tomorrow, rules: ScheduledMeetingRulesEntity(frequency: .daily, until: tomorrow))
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeetingWithOnOccurrence], upcomingOccurrences: [100: ScheduledMeetingOccurrenceEntity()])
        let viewModel = makeChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.first?.items.first?.scheduledMeeting.chatId == 1
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 10)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsTrue_asksForNotificationPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificationPermissionsValueToReturn = true
        let viewModel = makeChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 1)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsFalse_doesNotAskForNotificationPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificationPermissionsValueToReturn = false
        let viewModel = makeChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 0)
    }
    
    @MainActor
    func testMeetingTip_meetingListNotShown_shouldNotShowMeetingTip() {
        let sut = makeChatRoomsListViewModel()
        
        sut.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            sut.presentingCreateMeetingTip == true ||
            sut.presentingStartMeetingTip == true ||
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    @MainActor
    func testCreateMeetingTip_meetingListIsFirstShown_shouldShowCreateMeetingTip() {
        let sut = makeChatRoomsListViewModel(chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            sut.presentingCreateMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    @MainActor
    func testStartMeetingTip_meetingTipRecordIsCreateMeeting_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.createMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    @MainActor
    func testStartMeetingTip_meetingTipRecordIsStartMeeting_shouldShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    /// The tips are anchored to the future meeting rows, which the offline list keeps on screen,
    /// and their "Got it" writes a user attribute. The sibling create meeting tip already hides
    /// while offline; these two now do the same.
    @MainActor
    func testStartMeetingTip_whenOffline_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            userAttributeUseCase: userAttributeUseCase,
            chatViewMode: .meetings,
            isNewOfflineModeEnabled: true
        )

        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100

        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let unexpected = expectation(for: predicate, evaluatedWith: nil)
        unexpected.isInverted = true
        wait(for: [unexpected], timeout: 3)
    }

    @MainActor
    func testRecurringMeetingTip_whenOffline_shouldNotShowRecurringMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.recurringMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
            userAttributeUseCase: userAttributeUseCase,
            chatViewMode: .meetings,
            isNewOfflineModeEnabled: true
        )

        sut.loadChatRoomsIfNeeded()
        sut.recurringMeetingTipOffsetY = 100

        let predicate = NSPredicate { _, _ in
            sut.presentingRecurringMeetingTip == true
        }
        let unexpected = expectation(for: predicate, evaluatedWith: nil)
        unexpected.isInverted = true
        wait(for: [unexpected], timeout: 3)
    }

    @MainActor
    func testStartMeetingTip_meetingTipRecordIsStartMeetingAndScrollingList_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = 100
        sut.isMeetingListScrolling = true
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    @MainActor
    func testStartMeetingTip_meetingTipRecordIsStartMeetingAndTipIsNotVisiable_shouldNotShowStartMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.startMeetingTipOffsetY = nil
        
        let predicate = NSPredicate { _, _ in
            sut.presentingStartMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    @MainActor
    func testRecurringMeetingTip_meetingTipRecordIsStartMeeting_shouldNotShowRecurringMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.startMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.recurringMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 2)
    }
    
    @MainActor
    func testRecurringMeetingTip_meetingTipRecordIsStartMeeting_shouldShowRecurringMeetingTip() {
        let scheduleMeetingOnboarding = createScheduledMeetingOnboardingEntity(.recurringMeeting)
        let userAttributeUseCase = MockUserAttributeUseCase(scheduleMeetingOnboarding: scheduleMeetingOnboarding)
        let sut = makeChatRoomsListViewModel(userAttributeUseCase: userAttributeUseCase, chatViewMode: .meetings)
        
        sut.loadChatRoomsIfNeeded()
        sut.recurringMeetingTipOffsetY = 100
        
        let predicate = NSPredicate { _, _ in
            sut.presentingRecurringMeetingTip == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 5)
    }
    
    @MainActor
    func testArchivedChatsTapped_underTheChatListTab_shouldShowArchivedChatRooms() {
        // given
        let expectation = expectation(description: #function)
        let router = MockChatRoomsListRouter()
        router.showArchivedChatRoomsCompletion = { expectation.fulfill() }
        let sut = makeChatRoomsListViewModel(router: router)
        
        // when
        sut.archivedChatsTapped()
        
        wait(for: [expectation], timeout: 1)
        
        // then
        XCTAssertEqual(router.showArchivedChatRooms_calledTimes, 1)
    }
    
    @MainActor
    func testLoadChatRoomsIfNeeded_onCall_shouldCallRetryPendingConnections() {
        let retryPendingConnectionsUseCase = MockRetryPendingConnectionsUseCase()
        let chatUseCase = MockChatUseCase()
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase,
            retryPendingConnectionsUseCase: retryPendingConnectionsUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        XCTAssertEqual(chatUseCase.retryPendingConnections_calledTimes, 1)
        XCTAssertEqual(retryPendingConnectionsUseCase.retryPendingConnections_calledTimes, 1)
    }
    
    @MainActor
    func testShouldDisplayUnreadBadgeForChats_onChatsHasUnreadMessage_shouldBeTrue() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 1)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForChats == true
        }
    }
    
    @MainActor
    func testShouldDisplayUnreadBadgeForChats_onChatsHasNoUnreadMessage_shouldBeFalse() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 0)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForChats == false
        }
    }
    
    @MainActor
    func testShouldDisplayUnreadBadgeForMeetings_onMeetingsHasUnreadMessage_shouldBeTrue() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 1)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == true
        }
    }
    
    @MainActor
    func testShouldDisplayUnreadBadgeForMeetings_onMeetingsHasNoUnreadMessage_shouldBeFalse() {
        let chatUseCase = MockChatUseCase(
            items: [ChatListItemEntity(unreadCount: 0)],
            currentChatConnectionStatus: .online
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == false
        }
    }
    
    @MainActor
    func testShouldDisplayUnreadBadgeForMeetings_onChatConnectionStatusUpdateForNewUnreadMeetingMessage_shouldBeTrue() {
        let chatConnectionStatusUpdatePublisher = PassthroughSubject<ChatConnectionStatus, Never>()
        let chatUseCase = MockChatUseCase(
            chatConnectionStatusUpdatePublisher: chatConnectionStatusUpdatePublisher,
            items: [ChatListItemEntity(unreadCount: 1)]
        )
        let sut = makeChatRoomsListViewModel(
            chatUseCase: chatUseCase
        )
        
        sut.loadChatRoomsIfNeeded()
        chatConnectionStatusUpdatePublisher.send(.online)
        
        evaluate {
            sut.shouldDisplayUnreadBadgeForMeetings == true
        }
    }
    
    @MainActor
    func test_addChatButtonTapped_tracksAnalyticsEvent() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            router: MockChatRoomsListRouter(),
            tracker: mockTracker
        )
        
        viewModel.addChatButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ChatRoomsStartConversationMenuEvent()
            ]
        )
    }
    
    @MainActor
    func test_didLoadView_tracksScreenEvent() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            tracker: mockTracker
        )
        
        viewModel.trackScreenAppearance()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ChatScreenEvent()
            ]
        )
    }
    
    @MainActor
    func test_EmptyChats_tapInvite_tracksEvent() throws {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(tracker: mockTracker)
        let emptyState = try XCTUnwrap(viewModel.emptyViewState())
        let title = Strings.Localizable.Chat.Chats.EmptyState.V2.Button.Invite.title
        let button = try XCTUnwrap(emptyState.bottomButtonWith(title: title))
        button.triggerAction()
        XCTAssertTrackedAnalyticsEventsEqual(mockTracker.trackedEventIdentifiers, [InviteFriendsPressedEvent()])
    }
    
    @MainActor
    func test_EmptyChats_tapNewChat_tracksEvent() throws {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(tracker: mockTracker)
        let emptyState = try XCTUnwrap(viewModel.emptyViewState())
        let title = Strings.Localizable.Chat.Chats.EmptyState.Button.title
        let button = try XCTUnwrap(emptyState.bottomButtonWith(title: title))
        button.triggerAction()
        XCTAssertTrackedAnalyticsEventsEqual(mockTracker.trackedEventIdentifiers, [ChatRoomsStartConversationMenuEvent()])
    }
    
    @MainActor
    func test_TabSwitching_TracksEvents() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(tracker: mockTracker)
        viewModel.selectChatMode(.meetings)
        viewModel.selectChatMode(.chats)
        XCTAssertTrackedAnalyticsEventsEqual(mockTracker.trackedEventIdentifiers, [MeetingsTabEvent(), ChatsTabEvent()])
    }
    
    @MainActor
    func test_ChatStatusMenu_tracked() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            router: MockChatRoomsListRouter(),
            tracker: mockTracker
        )
        
        viewModel.chatStatusMenu(didSelect: .away)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ChatRoomStatusMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func test_chatDoNotDisturbMenu_tracked() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            router: MockChatRoomsListRouter(),
            tracker: mockTracker
        )
        
        viewModel.chatDoNotDisturbMenu(didSelect: .forever)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ChatRoomDNDMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func test_archivedChatsTapped_tracked() {
        let mockTracker = MockTracker()
        let viewModel = makeChatRoomsListViewModel(
            router: MockChatRoomsListRouter(),
            tracker: mockTracker
        )
        
        viewModel.archivedChatsTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                ArchivedChatsMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func test_contextMenuStartMeetingAction_noActiveCall_shouldPresentCreateMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: false)
        )
        
        viewModel.meetingContextMenu(didSelect: .startMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentCreateMeeting_calledTimes, 1)
    }
    
    @MainActor
    func test_contextMenuStartMeetingAction_activeCall_shouldNotPresentCreateMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: true)
        )
        
        viewModel.meetingContextMenu(didSelect: .startMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentCreateMeeting_calledTimes, 0)
    }
    
    @MainActor
    func test_contextMenuJoinMeetingAction_noActiveCall_shouldPresentEnterMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: false)
        )
        
        viewModel.meetingContextMenu(didSelect: .joinMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentEnterMeeting_calledTimes, 1)
    }
    
    @MainActor
    func test_contextMenuJoinMeetingAction_activeCall_shouldNotPresentEnterMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: true)
        )
        
        viewModel.meetingContextMenu(didSelect: .joinMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentEnterMeeting_calledTimes, 0)
    }
    
    @MainActor
    func test_contextMenuScheduleMeetingAction_noActiveCall_shouldPresentScheduleMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: false)
        )
        
        viewModel.meetingContextMenu(didSelect: .scheduleMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentScheduleMeeting_calledTimes, 1)
    }
    
    @MainActor
    func test_contextMenuScheduleMeetingAction_activeCall_shouldPresentScheduleMeetingView() async {
        let router = MockChatRoomsListRouter()
        let viewModel = makeChatRoomsListViewModel(
            router: router,
            chatUseCase: MockChatUseCase(isExistingActiveCall: true)
        )
        
        viewModel.meetingContextMenu(didSelect: .scheduleMeeting)
        await Task.megaYield()
        XCTAssertEqual(router.presentScheduleMeeting_calledTimes, 1)
    }
    
    // MARK: - Private methods
    
    private func pastDate(bySubtractHours numberOfHours: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -numberOfHours, to: Date())
    }
    
    private func futureDate(byAddingHours numberOfHours: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: numberOfHours, to: Date())
    }
    
    private func futureDate(byAddingDays numberOfDays: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: numberOfDays, to: Date())
    }
    
    private func createScheduledMeetingOnboardingEntity(_ tipType: ScheduledMeetingOnboardingTipType) -> ScheduledMeetingOnboardingEntity {
        ScheduledMeetingOnboardingEntity(ios: ScheduledMeetingOnboardingIos(record: ScheduledMeetingOnboardingRecord(currentTip: tipType)))
    }
    
    @MainActor
    private func makeChatRoomsListViewModel(
        router: some ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatPresenceUseCase: any ChatPresenceUseCaseProtocol = MockChatPresenceUseCase(),
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        userAttributeUseCase: any UserAttributeUseCaseProtocol = MockUserAttributeUseCase(),
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        permissionAlertRouter: MockPermissionAlertRouter? = nil,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol = MockChatListItemCacheUseCase(),
        retryPendingConnectionsUseCase: some RetryPendingConnectionsUseCaseProtocol = MockRetryPendingConnectionsUseCase(),
        tracker: some AnalyticsTracking = DIContainer.tracker,
        isNewOfflineModeEnabled: Bool = false
    ) -> ChatRoomsListViewModel {
        let _permissionHandler: MockPermissionAlertRouter = if let permissionAlertRouter {
            permissionAlertRouter
        } else {
            MockPermissionAlertRouter()
        }
        let sut = ChatRoomsListViewModel(
            router: router,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatPresenceUseCase: chatPresenceUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            accountUseCase: accountUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            userAttributeUseCase: userAttributeUseCase,
            chatType: chatType,
            chatViewMode: chatViewMode,
            permissionHandler: permissionHandler,
            permissionAlertRouter: _permissionHandler,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            retryPendingConnectionsUseCase: retryPendingConnectionsUseCase,
            tracker: tracker,
            featureFlagProvider: MockFeatureFlagProvider(list: [.offlineMode: isNewOfflineModeEnabled]),
            urlOpener: {_ in }
        )
        return sut
    }
}

final class MockChatRoomsListRouter: ChatRoomsListRouting {
    var openCallView_calledTimes = 0
    var presentStartConversation_calledTimes = 0
    var presentMeetingAlreadyExists_calledTimes = 0
    var presentCreateMeeting_calledTimes = 0
    var presentEnterMeeting_calledTimes = 0
    var presentScheduleMeeting_calledTimes = 0
    var presentWaitingRoom_calledTimes = 0
    var showInviteContactScreen_calledTimes = 0
    var showContactsOnMegaScreen_calledTimes = 0
    var showDetails_calledTimes = 0
    var present_calledTimes = 0
    var presentMoreOptionsForChat_calledTimes = 0
    var showGroupChatInfo_calledTimes = 0
    var showNoteToSelfInfo_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showMeetingOccurrences_calledTimes = 0
    var showContactDetailsInfo_calledTimes = 0
    var showArchivedChatRooms_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showErrorMessage_calledTimes = 0
    var showSuccessMessage_calledTimes = 0
    var editMeeting_calledTimes = 0
    private(set) var hideAds_calledTimes = 0
    
    var showArchivedChatRoomsCompletion: (() -> Void)?
    
    var navigationController: UINavigationController?
    
    nonisolated init() {}
    
    func presentStartConversation() {
        presentStartConversation_calledTimes += 1
    }
    
    func presentMeetingAlreadyExists() {
        presentMeetingAlreadyExists_calledTimes += 1
    }
    
    func presentCreateMeeting() {
        presentCreateMeeting_calledTimes += 1
    }
    
    func presentEnterMeeting() {
        presentEnterMeeting_calledTimes += 1
    }
    
    func presentScheduleMeeting() {
        presentScheduleMeeting_calledTimes += 1
    }
    
    func presentWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity) {
        presentWaitingRoom_calledTimes += 1
    }
    
    func showInviteContactScreen() {
        showInviteContactScreen_calledTimes += 1
    }
    
    func showContactsOnMegaScreen() {
        showContactsOnMegaScreen_calledTimes += 1
    }
    
    func showDetails(forChatId chatId: HandleEntity) {
        showDetails_calledTimes += 1
    }
    
    func present(alert: UIAlertController, animated: Bool) {
        present_calledTimes += 1
    }
    
    func presentMoreOptionsForChat(withDNDEnabled dndEnabled: Bool, actionsRequiringConnectionEnabled: Bool, dndAction: @escaping () -> Void, markAsReadAction: (() -> Void)?, infoAction: @escaping () -> Void, archiveAction: @escaping () -> Void) {
        presentMoreOptionsForChat_calledTimes += 1
    }
    
    func showGroupChatInfo(forChatRoom chatRoom: ChatRoomEntity) {
        showGroupChatInfo_calledTimes += 1
    }
    
    func showNoteToSelfInfo(noteToSelfChat: ChatRoomEntity) {
        showNoteToSelfInfo_calledTimes += 1
    }

    func showMeetingInfo(for scheduledMeeting: ScheduledMeetingEntity) {
        showMeetingInfo_calledTimes += 1
    }
    
    func showMeetingOccurrences(for scheduledMeeting: ScheduledMeetingEntity) {
        showMeetingOccurrences_calledTimes += 1
    }
    
    func showContactDetailsInfo(forUseHandle userHandle: HandleEntity, userEmail: String) {
        showContactDetailsInfo_calledTimes += 1
    }
    
    func showArchivedChatRooms() {
        showArchivedChatRooms_calledTimes += 1
        showArchivedChatRoomsCompletion?()
    }
    
    func openChatRoom(withChatId chatId: ChatIdEntity, publicLink: String?) {
        openChatRoom_calledTimes += 1
    }
    
    func openCallView(for call: CallEntity, in chatRoom: ChatRoomEntity) {
        openCallView_calledTimes += 1
    }
    
    func showErrorMessage(_ message: String) {
        showErrorMessage_calledTimes += 1
    }
    
    func showSuccessMessage(_ message: String) {
        showSuccessMessage_calledTimes += 1
    }
    
    func edit(scheduledMeeting: ScheduledMeetingEntity) {
        editMeeting_calledTimes += 1
    }
    
    func hideAds() {
        hideAds_calledTimes += 1
    }
}
