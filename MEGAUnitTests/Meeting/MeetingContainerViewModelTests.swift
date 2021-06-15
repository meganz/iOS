import XCTest
@testable import MEGA

final class MeetingContainerViewModelTests: XCTestCase {

    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.showMeetingUI_calledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsGuest() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, hasUserLoggedIn: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController()), expectedCommands: [])
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
    }
    
    func testAction_hangCall_attendeeIsParticipantOrModerator() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController()), expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_backButtonTap() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .tapOnBackButton, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_ChangeMenuVisibility() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: true, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .changeMenuVisibility, expectedCommands: [])
        XCTAssert(router.toggleFloatingPanel_CalledTimes == 1)
    }

    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: false, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: false, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let router = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let viewModel = MeetingContainerViewModel(router: router, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton(), completion: nil), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
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

    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
    
    func dismiss(completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        shareLink_calledTimes += 1
    }
    
    func renameChat() {
        renameChat_calledTimes += 1
    }
}

