import XCTest
@testable import MEGA

final class MeetingCreateViewModelTests: XCTestCase {
    func testAction_onViewReady_createMeeting() {
        let router = MockMeetingCreateRouter()
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .start,
                                                 meetingUseCase: MockMeetingCreatingUseCase(),
                                                 audioSessionUseCase: audioSession,
                                                 callsUseCase: MockCallsUseCase(),
                                                 localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 chatRoomUseCase: MockChatRoomUseCase(),
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 userUseCase: MockUserUseCase(handle: 0),
                                                 link: nil,
                                                 userHandle: 0)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: audioSession.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSession.isBluetoothAudioRouteAvailable),
                .configView(title: "test name Meeting", subtitle: "", type: .start, isMicrophoneEnabled: false),
                .updateMicrophoneButton(enabled: false)
             ])
    }
    
    func testAction_onViewReady_joinMeeting() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: "test name Meeting", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)

        useCase.chatCallCompletion = .success(chatRoom)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: audioSession,
                                                 callsUseCase: MockCallsUseCase(),
                                                 localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 chatRoomUseCase: MockChatRoomUseCase(),
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 userUseCase: MockUserUseCase(handle: 0),
                                                 link: "",
                                                 userHandle: 0)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: audioSession.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSession.isBluetoothAudioRouteAvailable),
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "test name Meeting", subtitle: "", type: .join, isMicrophoneEnabled: false)
             ])
    }
    
    func testAction_updateSpeakerButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: audioSession,
                                                 callsUseCase: MockCallsUseCase(),
                                                 localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 chatRoomUseCase: MockChatRoomUseCase(),
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 userUseCase: MockUserUseCase(handle: 0),
                                                 link: nil,
                                                 userHandle: 0)
        test(viewModel: viewModel,
             action: .didTapSpeakerButton,
             expectedCommands: [
                .updatedAudioPortSelection(audioPort: audioSession.currentSelectedAudioPort, bluetoothAudioRouteAvailable: audioSession.isBluetoothAudioRouteAvailable)
             ])
    }
    
    func testAction_didTapCloseButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)

        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: MockAudioSessionUseCase(),
                                                 callsUseCase: MockCallsUseCase(),
                                                 localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 chatRoomUseCase: MockChatRoomUseCase(),
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 userUseCase: MockUserUseCase(handle: 0),
                                                 link: nil,
                                                 userHandle: 0)
        
        viewModel.dispatch(.didTapCloseButton)
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_joinChatCall() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: "test name Meeting", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, chatType: .meeting)

        useCase.chatCallCompletion = .success(chatRoom)
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)

        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .start,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: MockAudioSessionUseCase(),
                                                 callsUseCase: MockCallsUseCase(),
                                                 localVideoUseCase: MockCallsLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 chatRoomUseCase: MockChatRoomUseCase(),
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 userUseCase: MockUserUseCase(handle: 0),
                                                 link: nil,
                                                 userHandle: 0)
        
        viewModel.dispatch(.didTapStartMeetingButton)
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(router.goToMeetingRoom_calledTimes == 1)

    }
    
}

final class MockMeetingCreateRouter: MeetingCreatingViewRouting {
    var dismiss_calledTimes = 0
    var goToMeetingRoom_calledTimes = 0
    var openChatRoom_calledTimes = 0
    var showVideoPermissionError_calledTimes = 0
    var showAudioPermissionError_calledTimes = 0

    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool, isSpeakerEnabled: Bool) {
        goToMeetingRoom_calledTimes += 1
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        openChatRoom_calledTimes += 1
    }
    
    func showVideoPermissionError() {
        showVideoPermissionError_calledTimes += 1
    }
    
    func showAudioPermissionError() {
        showAudioPermissionError_calledTimes += 1
    }
    
}
