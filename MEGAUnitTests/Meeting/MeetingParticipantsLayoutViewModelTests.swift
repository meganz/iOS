import XCTest
@testable import MEGA

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    func testAction_onViewLoaded() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel,
             action: .onViewLoaded,
             expectedCommands: [
                .configView(title: chatRoom.title ?? "", subtitle: "", isUserAGuest: false, isOneToOne: false),
                .showWaitingForOthersMessage,
                .updateHasLocalAudio(false)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
    }
    
    func testAction_onViewLoaded_activeCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(clientSessions: [ChatSessionEntity(statusType: .inProgress)])
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
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
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
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
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        
        test(viewModel: viewModel, action: .tapOnView(onParticipantsView: false), expectedCommands: [.switchMenusVisibility])
    }
    
    func testAction_tapOnLayoutButton() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        viewModel.layoutMode = .grid
        test(viewModel: viewModel,
             action: .tapOnLayoutModeButton,
             expectedCommands: [.updateSpeakerViewFor(nil),
                                .switchLayoutMode(layout: .speaker, participantsCount: 0)
                                ])
    }
    
    func testAction_tapOnBackButton() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
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
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.landscape),
             expectedCommands: [.enableLayoutButton(false)])
    }
    
    func testAction_switchIphoneOrientation_toProtrait() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.portrait),
             expectedCommands: [.enableLayoutButton(true)])
    }
    
    func testAction_switchIphoneOrientation_toLandscape_forceGridLayout() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: MockChatRoomUseCase(), callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                      containerViewModel: containerViewModel,
                                      callUseCase: callUseCase,
                                      captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                      localVideoUseCase: MockCallLocalVideoUseCase(),
                                      remoteVideoUseCase: remoteVideoUseCase,
                                      chatRoomUseCase: MockChatRoomUseCase(),
                                      userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                      userImageUseCase: MockUserImageUseCase(),
                                      chatRoom: chatRoom,
                                      call: call)
        viewModel.layoutMode = .speaker
        test(viewModel: viewModel,
             action: .switchIphoneOrientation(.landscape),
             expectedCommands: [.switchLayoutMode(layout: .grid, participantsCount: 0),
                                .enableLayoutButton(false)])
    }
}

final class MockCallViewRouter: MeetingParticipantsLayoutRouting {
    var showRenameChatAlert_calledTimes = 0
    var didAddFirstParticipant_calledTimes = 0

    var viewModel: MeetingParticipantsLayoutViewModel? {
        return nil
    }
    
    func showRenameChatAlert() {
        showRenameChatAlert_calledTimes += 1
    }
    
    func didAddFirstParticipant() {
        didAddFirstParticipant_calledTimes += 1
    }
}
