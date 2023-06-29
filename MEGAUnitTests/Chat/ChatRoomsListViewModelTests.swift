import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ChatRoomsListViewModelTests: XCTestCase {
    var subscription: AnyCancellable?
    let chatsListMock = [ChatListItemEntity(chatId: 1, title: "Chat1"),
                         ChatListItemEntity(chatId: 3, title: "Chat2"),
                         ChatListItemEntity(chatId: 67, title: "Chat3")]
    let meetingsListMock = [ChatListItemEntity(chatId: 11, title: "Meeting 1", meeting: true),
                            ChatListItemEntity(chatId: 14, title: "Meeting 2", meeting: true),
                            ChatListItemEntity(chatId: 51, title: "Meeting 3", meeting: true)]
    
    func test_remoteChatStatusChange() {
        let userHandle: HandleEntity = 100
        let chatUseCase = MockChatUseCase(myUserHandle: userHandle)
        let viewModel = ChatRoomsListViewModel(chatUseCase: chatUseCase, accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100)))
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
    
    func testAction_networkNotReachable() {
        let networkUseCase = MockNetworkMonitorUseCase(connected: false)
        let viewModel = ChatRoomsListViewModel(
            networkMonitorUseCase: networkUseCase
        )
        
        networkUseCase.networkPathChanged(completion: { _ in
            XCTAssert(viewModel.isConnectedToNetwork == networkUseCase.isConnected())
        })
    }
    
    func testAction_addChatButtonTapped() {
        let router = MockChatRoomsListRouter()
        let viewModel = ChatRoomsListViewModel(router: router)
        
        viewModel.addChatButtonTapped()
        
        XCTAssert(router.presentStartConversation_calledTimes == 1)
    }
    
    func testSelectChatMode_inviteContactNow_shouldMatch() throws {
        assertContactsOnMegaViewStateWhenSelectedChatMode(isAuthorizedToAccessPhoneContacts: true, description: Strings.Localizable.inviteContactNow)
    }
    
    func testSelectChatMode_seeWhoIsAlreadyOnMega_shouldMatch() throws {
        assertContactsOnMegaViewStateWhenSelectedChatMode(isAuthorizedToAccessPhoneContacts: false, description: Strings.Localizable.seeWhoSAlreadyOnMEGA)
    }
    
    func testSelectChatsMode_inputAsChats_viewModelesShouldMatch() {
        let mockList = chatsListMock
        let viewModel = ChatRoomsListViewModel(
            chatUseCase: MockChatUseCase(items: mockList),
            chatViewMode: .meetings
        )
        viewModel.loadChatRoomsIfNeeded()

        let expectation = expectation(description: "Compare the past meetings")
        subscription = viewModel
            .$displayChatRooms
            .dropFirst()
            .sink {
                XCTAssert(mockList.map { ChatRoomViewModel(chatListItem: $0) } == $0)
                expectation.fulfill()
            }
        
        viewModel.selectChatMode(.chats)
        wait(for: [expectation], timeout: 6)
    }
    
    func testSelectChatsMode_inputAsMeeting_viewModelsShouldMatch() {
        let mockList = meetingsListMock
        let viewModel = ChatRoomsListViewModel(
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
        XCTAssertEqual(mockList.map { ChatRoomViewModel(chatListItem: $0) }, viewModel.displayPastMeetings)
    }
    
    func test_EmptyChatsList() {
        let viewModel = ChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    func test_ChatListWithoutViewOnScreen() {
        let viewModel = ChatRoomsListViewModel()
        XCTAssert(viewModel.displayChatRooms == nil)
    }
    
    func testDisplayFutureMeetings_whenEmpty_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let yesterday = try XCTUnwrap(futureDate(byAddingDays: -1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, endDate: yesterday)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting])
        let viewModel = ChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings != nil && viewModel.displayFutureMeetings != []
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        exception.isInverted = true
        wait(for: [exception], timeout: 5)
    }
    
    func testDisplayFutureMeetings_containsMultipleSections_shouldMatch() throws {
        let chatUseCase = MockChatUseCase(currentChatConnectionStatus: .online)
        let tomorrow = try XCTUnwrap(futureDate(byAddingDays: 1))
        let scheduleMeeting = ScheduledMeetingEntity(chatId: 1, endDate: tomorrow)
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [scheduleMeeting])
        let viewModel = ChatRoomsListViewModel(chatUseCase: chatUseCase, scheduledMeetingUseCase: scheduleMeetingUseCase, chatViewMode: .meetings)
        viewModel.loadChatRoomsIfNeeded()
        
        let predicate = NSPredicate { _, _ in
            viewModel.displayFutureMeetings?.first?.items.first?.scheduledMeeting.chatId == 1
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 10)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsTrue_asksForNotificaitonPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificaitonPermissionsValueToReturn = true
        let viewModel = ChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 1)
    }
    
    @MainActor
    func testAskForNotificationsPermissionsIfNeeded_IfPermissionHandlerReturnsFalse_doesNotAskForNotificaitonPermissions() async {
        let permissionHandler = MockDevicePermissionHandler()
        let permissionRouter = MockPermissionAlertRouter()
        permissionHandler.shouldAskForNotificaitonPermissionsValueToReturn = false
        let viewModel = ChatRoomsListViewModel(
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionRouter
        )
        await viewModel.askForNotificationsPermissionsIfNeeded()
        XCTAssertEqual(permissionRouter.presentModalNotificationsPermissionPromptCallCount, 0)
    }
    
    // MARK: - Private methods
    
    private func assertContactsOnMegaViewStateWhenSelectedChatMode(isAuthorizedToAccessPhoneContacts: Bool, description: String, line: UInt = #line) {
        let router = MockChatRoomsListRouter()
        let contactsUseCase = MockContactsUseCase(authorized: isAuthorizedToAccessPhoneContacts)
        let viewModel = ChatRoomsListViewModel(router: router, contactsUseCase: contactsUseCase, chatViewMode: .meetings)
        
        let expectation = expectation(description: "Waiting for contactsOnMegaViewState to be updated")
        
        subscription = viewModel
            .$contactsOnMegaViewState
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }

        viewModel.selectChatMode(.chats)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(viewModel.contactsOnMegaViewState?.description, description, line: line)
    }
    
    private func futureDate(byAddingDays numberOfDays: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: numberOfDays, to: Date())
    }
}

final class MockChatRoomsListRouter: ChatRoomsListRouting {
    
    var openCallView_calledTimes = 0
    var presentStartConversation_calledTimes = 0
    var presentMeetingAlreayExists_calledTimes = 0
    var presentCreateMeeting_calledTimes = 0
    var presentEnterMeeting_calledTimes = 0
    var presentScheduleMeeting_calledTimes = 0
    var showInviteContactScreen_calledTimes = 0
    var showContactsOnMegaScreen_calledTimes = 0
    var showDetails_calledTimes = 0
    var present_calledTimes = 0
    var presentMoreOptionsForChat_calledTimes = 0
    var showGroupChatInfo_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var showMeetingOccurrences_calledTimes = 0
    var showContactDetailsInfo_calledTimes = 0
    var showArchivedChatRooms_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showErrorMessage_calledTimes = 0
    var showSuccessMessage_calledTimes = 0

    var navigationController: UINavigationController?
    
    func presentStartConversation() {
        presentStartConversation_calledTimes += 1
    }
    
    func presentMeetingAlreayExists() {
        presentMeetingAlreayExists_calledTimes += 1
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
    
    func showInviteContactScreen() {
        showInviteContactScreen_calledTimes += 1
    }
    
    func showContactsOnMegaScreen() {
        showContactsOnMegaScreen_calledTimes += 1
    }
    
    func showDetails(forChatId chatId: HandleEntity, unreadMessagesCount: Int) {
        showDetails_calledTimes += 1
    }
    
    func present(alert: UIAlertController, animated: Bool) {
        present_calledTimes += 1
    }
    
    func presentMoreOptionsForChat(withDNDEnabled dndEnabled: Bool, dndAction: @escaping () -> Void, markAsReadAction: (() -> Void)?, infoAction: @escaping () -> Void, archiveAction: @escaping () -> Void) {
        presentMoreOptionsForChat_calledTimes += 1
    }
    
    func showGroupChatInfo(forChatRoom chatRoom: ChatRoomEntity) {
        showGroupChatInfo_calledTimes += 1
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
    }
    
    func openChatRoom(withChatId chatId: ChatIdEntity, publicLink: String?, unreadMessageCount: Int) {
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
}
