import XCTest
@testable import MEGA

final class MeetingParticpiantInfoViewModelTests: XCTestCase {
    
    func testAction_onViewReady_MyselfAsModerator_AttendeeIsAModeratorAndIsInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .moderator, isInContactList: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()

        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), sendMessageAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_MyselfAsModerator_AttendeeIsAModeratorAndNotInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .moderator, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), addContactAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_MyselfAsModerator_AttendeeIsAParticipantAndAlsoInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .particpant, isInContactList: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), sendMessageAction(), makeModeratorAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_MyselfAsModerator_AttendeeIsAParticipantAndNotInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .particpant, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), addContactAction(), makeModeratorAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_MyselfAsParticipant_AttendeeIsAParticipantAndAlsoInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .particpant, isInContactList: true)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: false,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), sendMessageAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_MyselfAsParticipant_AttendeeIsAParticipantAndNotInContactList() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .particpant, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: false,
                                                        router: router)
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction(), addContactAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_onViewReady_AttendeeIsAGuest() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        test(viewModel: viewModel,
             action: .onViewReady(imageSize: .zero),
             expectedCommands: [
                .configView(email: "test@email.com", actions: [infoAction()]),
                .updateName(name: "Test"),
                .updateAvatarImage(image: UIImage())
             ])
    }
    
    func testAction_showInfo() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.showInfo)
        XCTAssert(router.showInfo_calledTimes == 1)
    }
    
    func testAction_sendMessage() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomEntity = ChatRoomEntity(chatId: 1, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.sendMessage)
        XCTAssert(router.openChatRoom_calledTimes == 1)
    }
    
    func testAction_addToContact_success() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.addToContact)
        XCTAssert(router.showInviteSuccess_calledTimes == 1)
    }
    
    func testAction_addToContact_error() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .failure(.generic(""))),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.addToContact)
        XCTAssert(router.showInviteError_calledTimes == 1)
    }
    
    func testAction_makeModerator() {
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", attendeeType: .guest, isInContactList: false)
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNameCompletion: .success("Test"))
        let userImageUseCase = MockUserImageUseCase(result: .success(UIImage()))
        let router = MockMeetingParticpiantInfoViewRouter()
        
        
        let viewModel = MeetingParticpiantInfoViewModel(attendee: particpant,
                                                        userImageUseCase: userImageUseCase,
                                                        chatRoomUseCase: chatRoomUseCase,
                                                        userInviteUseCase: MockUserInviteUseCase(result: .success),
                                                        isMyselfModerator: true,
                                                        router: router)
        
        viewModel.dispatch(.makeModerator)
        XCTAssert(router.updateAttendeeAsModerator_calledTimes == 1)
    }
    
    //MARK:- Private methods
    
    private func infoAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("info", comment: ""),
                          detail: nil,
                          image: UIImage(named: "InfoMeetings"),
                          style: .default) {}
    }
    
    private func sendMessageAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("sendMessage", comment: ""),
                          detail: nil,
                          image: UIImage(named: "sendMessageMeetings"),
                          style: .default) {}
    }
    
    private func makeModeratorAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("Make Moderator", comment: ""),
                          detail: nil,
                          image: UIImage(named: "moderatorMeetings"),
                          style: .default) {}
    }
    
    private func addContactAction() -> ActionSheetAction {
        ActionSheetAction(title: NSLocalizedString("addContact", comment: ""),
                          detail: nil,
                          image: UIImage(named: "addContactMeetings"),
                          style: .default) {}
    }
}

final class MockMeetingParticpiantInfoViewRouter: MeetingParticpiantInfoViewRouting {
    var showInfo_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showInviteSuccess_calledTimes = 0
    var showInviteError_calledTimes = 0
    var updateAttendeeAsModerator_calledTimes = 0
    
    func showInfo() {
        showInfo_calledTimes += 1
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        openChatRoom_calledTimes += 1
    }
    
    func showInviteSuccess(email: String) {
        showInviteSuccess_calledTimes += 1
    }
    
    func showInviteError(_ error: InviteError, email: String) {
        showInviteError_calledTimes += 1
    }
    
    func updateAttendeeAsModerator() {
        updateAttendeeAsModerator_calledTimes += 1
    }
}
