@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import XCTest

class MeetingFloatingPanelViewModelTests: XCTestCase {
    
    func makeDevicePermissionHandler(authorized: Bool = false) -> MockDevicePermissionHandler {
        .init(
            photoAuthorization: .authorized,
            audioAuthorized: authorized,
            videoAuthorized: authorized
        )
    }
    
    func testAction_onViewReady_isMyselfModerator_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .reloadParticipantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewAppear_selectWaitingRoomList() {
        let viewModel = MeetingFloatingPanelViewModel(selectWaitingRoomList: true)
        test(viewModel: viewModel,
             action: .onViewAppear,
             expectedCommands: [
                .transitionToLongForm
             ])
    }
    
    func testAction_selectParticipantsInCall_isOneToOneCall_reloadViewDataForOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsInCall_isGroupCallAndModerator_reloadViewDataForGroupCallModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group, isOpenInviteEnabled: false)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [.listSelector, .allowNonHostToInvite], inviteSectionRow: [.invite], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsInCall_isGroupCallAndNoModerator_reloadViewDataForGroupCallNoModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsInCall_isGroupCallAndOpenInvite_reloadViewDataForGroupCallEnabledOpenInvite() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: true)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .inCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [.invite], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsNotInCall_isGroupCallAndModerator_reloadViewDataForGroupCallModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group, isOpenInviteEnabled: false)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .notInCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .notInCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsNotInCall_isGroupCallAndModerator_reloadViewDataForGroupCallNoModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: false)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .notInCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .notInCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsNotInCall_isGroupCallAndOpenInvite_reloadViewDataForGroupCallEnabledOpenInvite() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .group, isOpenInviteEnabled: true)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .notInCall),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .notInCall, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_selectParticipantsInWaitingRoom_isMeetingAndModerator_reloadViewDataForMeetingModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting, isWaitingRoomEnabled: true)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .waitingRoom),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall, .waitingRoom], selectedTab: .waitingRoom, participants: [], existsWaitingRoom: true))
             ])
    }
    
    func testAction_selectParticipantsInWaitingRoom_isMeetingAndNonModerator_reloadViewDataForMeetingNoModerator() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting, isWaitingRoomEnabled: true)

        let viewModel = MeetingFloatingPanelViewModel(chatRoom: chatRoom)
        test(viewModel: viewModel,
             action: .selectParticipantsList(selectedTab: .waitingRoom),
             expectedCommands: [
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [.listSelector], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .waitingRoom, participants: [], existsWaitingRoom: false))
             ])
    }
    
    func testAction_onViewReady_isMyselfModerator_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false)),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithFrontCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
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
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: true, cameraPosition: .front, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.hostControls, .invite, .participants], hostControlsRows: [.allowNonHostToInvite], inviteSectionRow: [], tabs: [.inCall, .notInCall, .waitingRoom], selectedTab: .inCall, participants: [], existsWaitingRoom: false)),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_VideoCallWithBackCamera() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(hasLocalVideo: true)
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
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
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: captureDevice,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: true, cameraPosition: .back, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: true),
                .reloadParticipantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isGroupMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .reloadParticipantsList(participants: []),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_isOneToOneMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .oneToOne)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: false, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: false, isMyselfAModerator: false),
                .updatedAudioPortSelection(audioPort: audioSessionUseCase.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSessionUseCase.isBluetoothAudioRouteAvailable),
                .reloadViewData(participantsListView: ParticipantsListView(sections: [.invite, .participants], hostControlsRows: [], inviteSectionRow: [], tabs: [.inCall, .notInCall], selectedTab: .inCall, participants: [], existsWaitingRoom: false)),
                .microphoneMuted(muted: true)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
    }
    
    func testAction_onViewReady_isMyselfParticipant_allowNonHostToAddParticipantsEnabled() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting, isOpenInviteEnabled: true)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(canInviteParticipants: true, isOneToOneCall: chatRoom.chatType == .oneToOne, isMeeting: chatRoom.chatType == .meeting, isVideoEnabled: false, cameraPosition: nil, allowNonHostToAddParticipantsEnabled: true, isMyselfAModerator: false),
                .reloadParticipantsList(participants: []),
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
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: MockMeetingFloatingPanelRouter(),
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        XCTAssert(router.inviteParticipants_calledTimes == 1)
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
        XCTAssert(router.inviteParticipants_calledTimes == 0)
    }
    
    func testAction_inviteParticipants_singleContactVisible() {
        let router = MockMeetingFloatingPanelRouter()
        let accountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible)
        ])
        let viewModel = MeetingFloatingPanelViewModel(router: router, accountUseCase: accountUseCase, chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()))
        test(viewModel: viewModel, action: .inviteParticipants, expectedCommands: [])
        XCTAssert(router.inviteParticipants_calledTimes == 1)
    }
    
    func testAction_inviteParticipants_singleAddedContactAndABlockedContact() {
        let router = MockMeetingFloatingPanelRouter()
        let mockAccountUseCase = MockAccountUseCase(contacts: [
            UserEntity(email: "user@email.com", handle: 101, visibility: .visible),
            UserEntity(email: "user@email.com", handle: 102, visibility: .blocked)
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
        XCTAssert(router.inviteParticipants_calledTimes == 1)
        viewModel.dispatch(.inviteParticipants)
        XCTAssert(router.inviteParticipants_calledTimes == 1)
    }
    
    func testAction_contextMenuTap() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let callUseCase = MockCallUseCase(call: CallEntity())
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .turnCamera(on: true),
             expectedCommands: [
                .cameraTurnedOn(on: true)
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: localVideoUseCase,
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        test(viewModel: viewModel,
             action: .turnCamera(on: false),
             expectedCommands: [
                .cameraTurnedOn(on: false)
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: callManagerUserCase,
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
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
        let router = MockMeetingFloatingPanelRouter()
        let audioSessionUseCase = MockAudioSessionUseCase()
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: audioSessionUseCase,
                                                      permissionHandler: makeDevicePermissionHandler(authorized: true),
                                                      captureDeviceUseCase: captureDeviceUseCase,
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true))
        let particpant = CallParticipantEntity(chatId: 100, participantId: 100, clientId: 100, isModerator: false, isInContactList: false, canReceiveVideoHiRes: true)
        test(viewModel: viewModel,
             action: .makeModerator(participant: particpant),
             expectedCommands: [
                .reloadParticipantsList(participants: [])
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
            case .configView(_, _, _, _, _, let allowNonHostToAddParticipantsEnabled, _):
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
            case .configView(_, _, _, _, _, let allowNonHostToAddParticipantsEnabled, _):
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
    
    func testAction_seeMoreParticipantsInWaitingRoomTapped_navigateToView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .oneToOne)
        let call = CallEntity()
        let router = MockMeetingFloatingPanelRouter()
        let callUseCase = MockCallUseCase(call: call)
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, callUseCase: callUseCase, callCoordinatorUseCase: MockCallCoordinatorUseCase())
        let viewModel = MeetingFloatingPanelViewModel(router: router,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: false,
                                                      callCoordinatorUseCase: MockCallCoordinatorUseCase(),
                                                      callUseCase: callUseCase,
                                                      audioSessionUseCase: MockAudioSessionUseCase(),
                                                      permissionHandler: makeDevicePermissionHandler(),
                                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                                      accountUseCase: MockAccountUseCase())
        
        test(viewModel: viewModel, action: .seeMoreParticipantsInWaitingRoomTapped, expectedCommands: [])
        XCTAssert(router.showWaitingRoomParticipantsList_calledTimes == 1)
    }
}

final class MockMeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    
    var videoPermissionError_calledTimes = 0
    var audioPermissionError_calledTimes = 0
    var dismiss_calledTimes = 0
    var shareLink_calledTimes = 0
    var inviteParticipants_calledTimes = 0
    var showContextMenu_calledTimes = 0
    var showAllContactsAlreadyAddedAlert_CalledTimes = 0
    var showNoAvailableContactsAlert_CalledTimes = 0
    var invitedParticipantHandles: [HandleEntity]?
    var showConfirmDenyAction_calledTimes = 0
    var showWaitingRoomParticipantsList_calledTimes = 0

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
        excludeParticipantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        inviteParticipants_calledTimes += 1
        if let invitedParticipantHandles = invitedParticipantHandles {
            selectedUsersHandler(invitedParticipantHandles)
        }
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showAllContactsAlreadyAddedAlert_CalledTimes += 1
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
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
    
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        showConfirmDenyAction_calledTimes += 1
    }
    
    func showWaitingRoomParticipantsList(for call: CallEntity) {
        showWaitingRoomParticipantsList_calledTimes += 1
    }
}
