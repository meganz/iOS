import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

class MeetingFloatingPanelViewModelTests: XCTestCase {
    
    func testAction_onViewReady_isMyselfModerator_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom,callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfModerator_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: true, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.videoDeviceSelectedString = "front"
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .front, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
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
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDevice,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: true, cameraPosition: .back, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_allowNonHostToAddParticipantsEnabled() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting, isOpenInviteEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneMeeting: false, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: true, isMyselfAModerator: false),
                .reloadParticpantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_hangCallOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .oneToOne)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_hangMeetingWithStandarPrivileges() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_hangMeetingWithModeratorPrivilegesNoOneElseInMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        viewModel.participantJoined(participant: CallParticipantEntity())

        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.dismiss_calledTimes == 1)
        XCTAssert(callManagerUserCase.endCall_calledTimes == 1)
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testAction_hangMeetingWithModeratorPrivilegesAndOtherParticipants() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        viewModel.participantJoined(participant: CallParticipantEntity())
        viewModel.participantJoined(participant: CallParticipantEntity())
        
        test(viewModel: viewModel, action: .hangCall(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.showHangOrEndCallDialog_calledTimes == 1)
    }
    
    func testAction_shareLink_Success() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let containerRouter = MockMeetingContainerRouter()
        let callUseCase = MockCallUseCase(call: call)
        let chatRoomUseCase = MockChatRoomUseCase(publicLinkCompletion: .success(""))
        let containerViewModel = MeetingContainerViewModel(router: containerRouter, chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(containerRouter.shareLink_calledTimes == 1)
    }
    
    func testAction_shareLink_Failure() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel, action: .shareLink(presenter: UIViewController(), sender: UIButton()), expectedCommands: [])
        XCTAssert(router.shareLink_calledTimes == 0)
    }
    
    func testAction_inviteParticipants() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase, chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()))
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticpants_calledTimes == 1)
    }
    
    func testAction_inviteParticipants_showAllContactsAlreadyAddedAlert() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase, chatRoomUseCase: chatRoomUseCase)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showAllContactsAlreadyAddedAlert_CalledTimes == 1)
    }
    
    func testAction_inviteParticipants_showNoAvailableContactsAlert() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .blocked)
        ])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showNoAvailableContactsAlert_CalledTimes == 1)
    }
    
    func testAction_inviteParticipants_singleContactBlocked() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .blocked)
        ])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticpants_calledTimes == 0)
    }
    
    func testAction_inviteParticipants_singleContactVisible() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase, chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()))
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticpants_calledTimes == 1)
    }
    
    func testAction_inviteParticipants_singleAddedContactAndABlockedContact() {
        let router = MockMeetingFloatingPanelRouter()
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible),
            UserEntity(email: "user@email.com", handle: 102, visibility: .blocked),
        ])
        let chatRoomUseCase = MockChatRoomUseCase(myPeerHandles: [101])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: mockAccountUseCase, chatRoomUseCase: chatRoomUseCase)
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.showAllContactsAlreadyAddedAlert_CalledTimes == 1)
    }
    
    func testAction_inviteParticipants_reAddParticipantScenario() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let viewModel = MeetingFloatingPanelViewModel(
            router: router,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        viewModel.dispatch(.inviteParticipants)
        XCTAssert(router.inviteParticpants_calledTimes == 1)
        viewModel.dispatch(.inviteParticipants)
        XCTAssert(router.inviteParticpants_calledTimes == 1)
    }
    
    func testAction_contextMenuTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel, action: .onContextMenuTap(presenter: UIViewController(), sender: UIButton(), participant: particpant), expectedCommands: [])
        XCTAssert(router.showContextMenu_calledTimes == 1)
    }
    
    func testAction_muteCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: true), expectedCommands: [.microphoneMuted(muted: true)])
        XCTAssert(callManagerUserCase.muteUnmute_Calls == [true])
    }
    
    func testAction_unmuteCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel, action: .muteUnmuteCall(mute: false), expectedCommands: [.microphoneMuted(muted: false)])
        XCTAssert(callManagerUserCase.muteUnmute_Calls == [false])
    }
    
    func testAction_turnCameraOnBackCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Back")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
                .updatedCameraPosition(position: .back)
             ])
        
    }
    
    func testAction_turnCameraOnFrontCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true),
             ])
        
    }
    
    
    func testAction_turnCameraOffCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .turnCamera(on: false),
             expectedCommands: [
                .cameraTurnedOn(on: false),
             ])
    }
    
    func testAction_switchBackCameraOn() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
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
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Back"
        let callManagerUserCase = MockCallCoordinatorUseCase()
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: callManagerUserCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
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
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
        test(viewModel: viewModel,
             action: .switchCamera(backCameraOn: false),
             expectedCommands: [
                .updatedCameraPosition(position: .front)
             ])
        XCTAssert(localVideoUseCase.selectedCamera_calledTimes == 0)
    }
    
    func testAction_enableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
        test(viewModel: viewModel,
             action: .enableLoudSpeaker,
             expectedCommands: [])
        XCTAssert(audioSessionUseCase.enableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_disableLoudSpeaker() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        
        test(viewModel: viewModel,
             action: .disableLoudSpeaker,
             expectedCommands: [])
        XCTAssert(audioSessionUseCase.disableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_ChangeModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let localVideoUseCase = MockCallLocalVideoUseCase()
        localVideoUseCase.enableDisableVideoCompletion = .success(())
        localVideoUseCase.videoDeviceSelectedString = "Front"
        let captureDeviceUseCase =  MockCaptureDeviceUseCase(cameraPositionName: "Front")
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: true, videoAccessAuthorized: true)
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel,
             action: .makeModerator(participant: particpant),
             expectedCommands: [
                .reloadParticpantsList(participants: [])
             ]
        )
    }
    
    func testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteEnabled() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomEntity = ChatRoomEntity(chatId: 100, isOpenInviteEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = MeetingFloatingPanelViewModel(
            router: router,
            chatRoom: chatRoomEntity,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        let expectation = expectation(description: "testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteEnabled")
        viewModel.invokeCommand = { command in
            switch command {
            case .configView(_ , _, _, _, let allowNonHostToAddParticipantsEnabled, _):
                XCTAssertTrue(allowNonHostToAddParticipantsEnabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.onViewReady)
        chatRoomUseCase.allowNonHostToAddParticipantsValueChangedSubject.send(true)
        waitForExpectations(timeout: 10)
    }
    
    func testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteDisabled() {
        let router = MockMeetingFloatingPanelRouter()
        router.invitedParticipantHandles = [101]
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let chatRoomEntity = ChatRoomEntity(chatId: 100, isOpenInviteEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = MeetingFloatingPanelViewModel(
            router: router,
            chatRoom: chatRoomEntity,
            accountUseCase: mockAccountUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        let expectation = expectation(description: "testAction_allowNonHostToAddParticipantsValueChanged_isOpenInviteDisabled")
        viewModel.invokeCommand = { command in
            switch command {
            case .configView(_ , _, _, _, let allowNonHostToAddParticipantsEnabled, _):
                XCTAssertFalse(allowNonHostToAddParticipantsEnabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.onViewReady)
        chatRoomUseCase.allowNonHostToAddParticipantsValueChangedSubject.send(true)
        waitForExpectations(timeout: 10)
    }
    
    func testAction_updateAllowNonHostToAddParticipants_allowNonHostToAddParticipantsEnabled() {
        let chatRoomUseCase = MockChatRoomUseCase(allowNonHostToAddParticipantsEnabled: true)
        let viewModel = MeetingFloatingPanelViewModel(chatRoomUseCase: chatRoomUseCase)
        
        let expectation = expectation(description: "testAction_updateAllowNonHostToAddParticipants")
        viewModel.invokeCommand = { command in
            switch command {
            case .updateAllowNonHostToAddParticipants(let enabled):
                XCTAssertTrue(enabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.allowNonHostToAddParticipants(enabled: false))
        waitForExpectations(timeout: 10)
    }
    
    func testAction_updateAllowNonHostToAddParticipants_allowNonHostToAddParticipantsDisabled() {
        let chatRoomUseCase = MockChatRoomUseCase(allowNonHostToAddParticipantsEnabled: false)
        let viewModel = MeetingFloatingPanelViewModel(chatRoomUseCase: chatRoomUseCase)
        
        let expectation = expectation(description: "testAction_updateAllowNonHostToAddParticipants")
        viewModel.invokeCommand = { command in
            switch command {
            case .updateAllowNonHostToAddParticipants(let enabled):
                XCTAssertFalse(enabled)
                expectation.fulfill()
            default:
                break
            }
        }
        
        viewModel.dispatch(.allowNonHostToAddParticipants(enabled: true))
        waitForExpectations(timeout: 10)
    }
}

final class MockMeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    
    var videoPermissionError_calledTimes = 0
    var audioPermissionError_calledTimes = 0
    var dismiss_calledTimes = 0
    var shareLink_calledTimes = 0
    var inviteParticpants_calledTimes = 0
    var showContextMenu_calledTimes = 0
    var showAllContactsAlreadyAddedAlert_CalledTimes = 0
    var showNoAvailableContactsAlert_CalledTimes = 0
    var invitedParticipantHandles: [HandleEntity]?

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
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticpantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        inviteParticpants_calledTimes += 1
        if let invitedParticipantHandles = invitedParticipantHandles {
            selectedUsersHandler(invitedParticipantHandles)
        }
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showAllContactsAlreadyAddedAlert_CalledTimes += 1
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory){
        showNoAvailableContactsAlert_CalledTimes += 1
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
    
    static func mock() -> DevicePermissionCheckingProtocol {
        mock(
            albumAuthorizationStatus: .authorized,
            audioAccessAuthorized: true,
            videoAccessAuthorized: true
        )
    }
}
