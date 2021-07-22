import XCTest
@testable import MEGA

class MeetingFloatingPanelViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isMyselfModerator_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfModerator_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .oneToOne)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: true, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithFrontCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: true, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.videoDeviceSelectedString = "front"
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .front),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithBackCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .moderator, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: true, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.videoDeviceSelectedString = "back"
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .back),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callsUseCase: MockCallsUseCase(), chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let callUseCase = MockCallsUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_hangCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let callManagerUserCase = MockCallManagerUseCase()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
    
    func testAction_inviteParticipants() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel, action: .inviteParticipants(presenter: UIViewController()), expectedCommands: [])
        XCTAssert(router.inviteParticpants_calledTimes == 1)
    }
    
    func testAction_contextMenuTap() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", isModerator: false, isInContactList: false, videoResolution: .high)
        test(viewModel: viewModel, action: .onContextMenuTap(presenter: UIViewController(), sender: UIButton(), attendee: particpant), expectedCommands: [])
        XCTAssert(router.showContextMenu_calledTimes == 1)
    }
    
    func testAction_muteCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: true), expectedCommands: [.microphoneMuted(muted: true)])
        XCTAssert(callManagerUserCase.muteUnmute_CalledTimes == 1)
    }
    
    func testAction_unmuteCall() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let callManagerUserCase = MockCallManagerUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: false), expectedCommands: [.microphoneMuted(muted: false)])
        XCTAssert(callManagerUserCase.muteUnmute_CalledTimes == 1)
    }
    
    func testAction_turnCameraOnBackCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Back")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
             ])

    }
    
    func testAction_turnCameraOnFrontCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
             ])

    }

    
    func testAction_turnCameraOffCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        test(viewModel: viewModel,
             action: .turnCamera(on: false),
             expectedCommands: [
                .cameraTurnedOn(on: false),
             ])
    }
    
    func testAction_switchBackCameraOn() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: true, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: true),
             expectedCommands: [
                .updatedCameraPosition(position: .back)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 1)
    }
    
    func testAction_switchBackFrontCameraOn() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: true, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: false),
             expectedCommands: [
                .updatedCameraPosition(position: .front)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 1)
    }
    
    func testAction_alreadyOnFrontCamera_switchOnFrontCamera() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: true, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: false),
             expectedCommands: [
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 0)
    }
    
    func testAction_enableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel,
             action: .enableLoudSpeaker,
             expectedCommands: [])
        XCTAssert(audioSessionUseCase.enableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_disableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        
        test(viewModel: viewModel,
             action: .disableLoudSpeaker,
             expectedCommands: [.updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable)
             ])
        XCTAssert(audioSessionUseCase.disableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_ChangeModerator() {
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: nil, unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)
        let call = CallEntity(status: .inProgress, chatId: 0, callId: 0, changeTye: nil, duration: 0, initialTimestamp: 0, finalTimestamp: 0, hasLocalAudio: false, hasLocalVideo: false, termCodeType: nil, isRinging: false, callCompositionChange: nil, numberOfParticipants: 0, isOnHold: false, sessionClientIds: [], clientSessions: [], participants: [], uuid: UUID(uuidString: "45adcd56-a31c-11eb-bcbc-0242ac130002")!)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallsUseCase()
        callUseCase.callEntity = call
        let localVideoUseCase = MockCallsLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, call: call, callsUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100), authUseCase: MockAuthUseCase(isUserLoggedIn: true), isAnsweredFromCallKit: false)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callsUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, networkQuality: 1, email: "test@email.com", isModerator: false, isInContactList: false, videoResolution: .high)
        test(viewModel: viewModel,
             action: .makeModerator(participant: particpant),
             expectedCommands: [
             .reloadParticpantsList(participants: [])
             ]
        )
    }
}

final class MockMeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    var videoPermissionError_calledTimes = 0
    var audioPermissionError_calledTimes = 0
    var dismiss_calledTimes = 0
    var shareLink_calledTimes = 0
    var inviteParticpants_calledTimes = 0
    var showContextMenu_calledTimes = 0
    
    var viewModel: MeetingFloatingPanelViewModel? {
        return nil
    }
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func shareLink(presenter: UIViewController, sender: UIButton, link: String) {
        shareLink_calledTimes += 1
    }
    
    func inviteParticipants(
        presenter: UIViewController,
        excludeParticpants: [UInt64]?,
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    ) {
        inviteParticpants_calledTimes += 1
    }
    
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         attendee: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        showContextMenu_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        videoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        audioPermissionError_calledTimes += 1
    }
}

extension DevicePermissionCheckingProtocol {
    
    static func mock(albumAuthorizationStatus: PhotoAuthorization,
                     audioAccessAuthorized: Bool,
                     videoAccessAuthorized: Bool) -> DevicePermissionCheckingProtocol {
        Self.init(getAlbumAuthorizationStatus: { callback in
            callback(albumAuthorizationStatus)
        }, getAudioAuthorizationStatus: { callback in
            callback(audioAccessAuthorized)
        }, getVideoAuthorizationStatus: { callback in
            callback(videoAccessAuthorized)
        })
    }
}
