import XCTest
@testable import MEGA
import MEGADomainMock
import MEGADomain

final class MeetingCreatingViewModelTests: XCTestCase {
    func testAction_onViewReady_createMeeting() {
        let router = MockMeetingCreateRouter()
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .start,
                                                 meetingUseCase: MockMeetingCreatingUseCase(userName: "Test Name"),
                                                 audioSessionUseCase: audioSession,
                                                 localVideoUseCase: MockCallLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                 megaHandleUseCase: MockMEGAHandleUseCase(),
                                                 link: nil,
                                                 userHandle: 0)
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(title: "Test Name's meeting", type: .start, isMicrophoneEnabled: false)
             ])
    }
    
    func testAction_onViewReady_joinMeeting() {
        let router = MockMeetingCreateRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let useCase = MockMeetingCreatingUseCase(userName: "Test Name", chatCallCompletion: .success(chatRoom))
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: audioSession,
                                                 localVideoUseCase: MockCallLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                 megaHandleUseCase: MockMEGAHandleUseCase(),
                                                 link: "",
                                                 userHandle: 0)
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "Unit tests", type: .join, isMicrophoneEnabled: false)
             ])
    }
    
    func testAction_updateSpeakerButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase(userName: "Test Name")
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)
        let audioSession = MockAudioSessionUseCase()
        
        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: audioSession,
                                                 localVideoUseCase: MockCallLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                 megaHandleUseCase: MockMEGAHandleUseCase(),
                                                 link: nil,
                                                 userHandle: 0)
        test(viewModel: viewModel,
             action: .didTapSpeakerButton,
             expectedCommands: [
             ])
        XCTAssert(audioSession.disableLoudSpeaker_calledTimes == 1)
    }
    
    func testAction_didTapCloseButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase(userName: "Test Name")
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)

        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .join,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: MockAudioSessionUseCase(),
                                                 localVideoUseCase: MockCallLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                 megaHandleUseCase: MockMEGAHandleUseCase(),
                                                 link: nil,
                                                 userHandle: 0)
        
        viewModel.dispatch(.didTapCloseButton)
        XCTAssert(router.dismiss_calledTimes == 1)
    }
    
    func testAction_joinChatCall() {
        let router = MockMeetingCreateRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, chatType: .meeting)
        let useCase = MockMeetingCreatingUseCase(userName: "Test Name", chatCallCompletion: .success(chatRoom))
        let devicePermissonCheckingUseCase = DevicePermissionCheckingProtocol.mock(albumAuthorizationStatus: .authorized, audioAccessAuthorized: false, videoAccessAuthorized: false)

        let viewModel = MeetingCreatingViewModel(router: router,
                                                 type: .start,
                                                 meetingUseCase: useCase,
                                                 audioSessionUseCase: MockAudioSessionUseCase(),
                                                 localVideoUseCase: MockCallLocalVideoUseCase(),
                                                 captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                 devicePermissionUseCase: devicePermissonCheckingUseCase,
                                                 userImageUseCase: MockUserImageUseCase(),
                                                 accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
                                                 megaHandleUseCase: MockMEGAHandleUseCase(),
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
