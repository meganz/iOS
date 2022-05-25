import XCTest
@testable import MEGA

final class MeetingContainerViewModelTests: XCTestCase {

    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callManagerUseCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: MockCallUseCase(call: CallEntity()), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUseCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.showMeetingUI_calledTimes == 1)
        XCTAssert(callManagerUseCase.addCallRemoved_CalledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsGuest() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: callEntity)
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: false, isGuest: true), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.showEndMeetingOptions_calledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsParticipantOrModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callEntity = CallEntity(chatId: 1, callId: 1, duration: 1, initialTimestamp: 1, finalTimestamp: 1, numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: callEntity)
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_backButtonTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: MockCallUseCase(call: CallEntity()), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_ChangeMenuVisibility() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: MockCallUseCase(call: CallEntity()), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(router.toggleFloatingPanel_CalledTimes == 1)
    }

    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
    
    func testAction_displayParticipantInMainView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .displayParticipantInMainView(particpant), expectedCommands: [])
        XCTAssert(router.displayParticipantInMainView_calledTimes == 1)
    }
    
    func testAction_didDisplayParticipantInMainView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .didDisplayParticipantInMainView(particpant), expectedCommands: [])
        XCTAssert(router.didDisplayParticipantInMainView_calledTimes == 1)
    }
    
    func testAction_didSwitchToGridView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .didSwitchToGridView, expectedCommands: [])
        XCTAssert(router.didSwitchToGridView_calledTimes == 1)
    }
}

final class MockMeetingContainerRouter: MeetingContainerRouting {
    var showMeetingUI_calledTimes = 0
    var dismiss_calledTimes = 0
    var toggleFloatingPanel_CalledTimes = 0
    var showEndMeetingOptions_calledTimes = 0
    var showOptionsMenu_calledTimes = 0
    var shareLink_calledTimes = 0
    var renameChat_calledTimes = 0
    var showMeetingError_calledTimes = 0
    var enableSpeaker_calledTimes = 0
    var displayParticipantInMainView_calledTimes = 0
    var didDisplayParticipantInMainView_calledTimes = 0
    var didSwitchToGridView_calledTimes = 0

    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel, sender: UIButton) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        shareLink_calledTimes += 1
    }
    
    func renameChat() {
        renameChat_calledTimes += 1
    }
    
    func showShareMeetingError() {
        showMeetingError_calledTimes += 1
    }
    
    func enableSpeaker(_ enable: Bool) {
        enableSpeaker_calledTimes += 1
    }
    
    func displayParticipantInMainView(_ participant: CallParticipantEntity) {
        displayParticipantInMainView_calledTimes += 1
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity){
        didDisplayParticipantInMainView_calledTimes += 1
    }
    
    func didSwitchToGridView(){
        didSwitchToGridView_calledTimes += 1
    }
}
