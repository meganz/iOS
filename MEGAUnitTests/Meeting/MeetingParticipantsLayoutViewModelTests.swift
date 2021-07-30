import XCTest
@testable import MEGA

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    func testAction_onViewLoaded() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel,
             action: .onViewLoaded,
             expectedCommands: [
                .configView(title: chatRoom.title ?? "", subtitle: "", isUserAGuest: false, isOneToOne: false),
                .showWaitingForOthersMessage,
                .startCompatibilityWarningViewTimer,
                .updateHasLocalAudio(false)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
    }
    
    func testAction_onViewLoaded_activeCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [1], clientSessions: [ChatSessionEntity(statusType: .inProgress, hasAudio: true, hasVideo: false, peerId: MEGAInvalidHandle, clientId: 1, audioDetected: false, isOnHold: false, changes: 0, isHighResolution: false)], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel,
             action: .onViewLoaded,
             expectedCommands: [
                .configView(title: chatRoom.title ?? "", subtitle: "", isUserAGuest: false, isOneToOne: false),
                .updateHasLocalAudio(false)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
        XCTAssert(callUseCase.createActiveSessions_calledTimes == 1)
    }
    
    func testAction_onViewReady() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configLocalUserView(position: .front)
             ])
    }
    
    func testAction_tapOnView() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel, action: .tapOnView(onParticipantsView: false), expectedCommands: [.switchMenusVisibility])
    }
    
    func testAction_tapOnLayoutButton() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        viewModel.layoutMode = .grid
        test(viewModel: viewModel,
             action: .tapOnLayoutModeButton,
             expectedCommands: [.switchLayoutMode(layout: .speaker, participantsCount: 0),
                                .updateSpeakerViewFor(nil)])
    }
    
    func testAction_tapOnBackButton() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        viewModel.layoutMode = .grid
        test(viewModel: viewModel,
             action: .tapOnBackButton,
             expectedCommands: [])
        XCTAssert(remoteVideoUseCase.disableAllRemoteVideos_CalledTimes == 1)
    }
    
    func testAction_switchIphoneOrientation_toLandscape() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.landscape),
             expectedCommands: [.toggleLayoutButton])
    }
    
    func testAction_switchIphoneOrientation_toProtrait() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.portrait),
             expectedCommands: [.toggleLayoutButton])
    }
    
    func testAction_switchIphoneOrientation_toLandscape_forceGridLayout() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        viewModel.layoutMode = .speaker
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.landscape),
             expectedCommands: [.switchLayoutMode(layout: .grid, participantsCount: 0),
                                .toggleLayoutButton])
    }
    
    func testAction_callTerminated() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: "Unit Tests", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let callUseCase = MockCallUseCase()
        let remoteVideoUseCase = MockCallsRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let router = MockCallViewRouter()
        let viewModel = MeetingParticipantsLayoutViewModel(router: router,
                                      containerViewModel: containerViewModel,
                                      callsUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        viewModel.callTerminated()
        XCTAssert(router.dismissAndShowPasscodeIfNeeded_calledTimes == 1)
    }
}

final class MockCallViewRouter: MeetingParticipantsLayoutRouting {
    var dismissAndShowPasscodeIfNeeded_calledTimes = 0
    var showRenameChatAlert_calledTimes = 0
    var didAddFirstParticipant_calledTimes = 0

    var viewModel: MeetingParticipantsLayoutViewModel? {
        return nil
    }
    
    func dismissAndShowPasscodeIfNeeded() {
        dismissAndShowPasscodeIfNeeded_calledTimes += 1
    }
    
    func showRenameChatAlert() {
        showRenameChatAlert_calledTimes += 1
    }
    
    func didAddFirstParticipant() {
        didAddFirstParticipant_calledTimes += 1
    }
}
