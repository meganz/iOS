import XCTest
@testable import MEGA

class MeetingFloatingPanelViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isMyselfModerator_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfModerator_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: true, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithFrontCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let callUseCase = MockCallUseCase(call: call)
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.videoDeviceSelectedString = "front"
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .front),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true),
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithBackCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let callUseCase = MockCallUseCase(call: call)
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.videoDeviceSelectedString = "back"
        var captureDevice = MockCaptureDeviceUseCase()
        captureDevice.cameraPositionName = "back"
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDevice,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .back),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_hangCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallManagerUseCase()
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
    
    func testAction_inviteParticipants() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticpants_calledTimes == 1)
    }
    
    func testAction_contextMenuTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .onContextMenuTap(presenter: UIViewController(), sender: UIButton(), participant: particpant), expectedCommands: [])
        XCTAssert(router.showContextMenu_calledTimes == 1)
    }
    
    func testAction_muteCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: true), expectedCommands: [.microphoneMuted(muted: true)])
        XCTAssert(callManagerUserCase.muteUnmute_CalledTimes == 1)
    }
    
    func testAction_unmuteCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallManagerUseCase()
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: false), expectedCommands: [.microphoneMuted(muted: false)])
        XCTAssert(callManagerUserCase.muteUnmute_CalledTimes == 1)
    }
    
    func testAction_turnCameraOnBackCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Back")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
                .updatedCameraPosition(position: .back)
             ])
        
    }
    
    func testAction_turnCameraOnFrontCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
             ])
        
    }
    
    
    func testAction_turnCameraOffCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        test(viewModel: viewModel,
             action: .turnCamera(on: false),
             expectedCommands: [
                .cameraTurnedOn(on: false),
             ])
    }
    
    func testAction_switchBackCameraOn() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: true),
             expectedCommands: [
                .updatedCameraPosition(position: .back)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 1)
    }
    
    func testAction_switchBackFrontCameraOn() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: false),
             expectedCommands: [
                .updatedCameraPosition(position: .front)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 1)
    }
    
    func testAction_alreadyOnFrontCamera_switchOnFrontCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: false),
             expectedCommands: [
                .updatedCameraPosition(position: .front)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 0)
    }
    
    func testAction_enableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel,
             action: .enableLoudSpeaker,
             expectedCommands: [])
        XCTAssert(audioSessionUseCase.enableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_disableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        
        test(viewModel: viewModel,
             action: .disableLoudSpeaker,
             expectedCommands: [])
        XCTAssert(audioSessionUseCase.disableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_ChangeModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let callManagerUserCase = MockCallManagerUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let noUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: callManagerUserCase, userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true), noUserJoinedUseCase: noUserJoinedUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callManagerUseCase: MockCallManagerUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
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
        excludeParticpants: NSMutableDictionary,
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    ) {
        inviteParticpants_calledTimes += 1
    }
    
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         participant: CallParticipantEntity,
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
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {}
    
    func didSwitchToGridView() {}
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
