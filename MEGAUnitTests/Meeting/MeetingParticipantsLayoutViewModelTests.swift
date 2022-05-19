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
             expectedCommands: [
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
    
    func testAction_singleParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedParticipantsNamesArray = ["User1"]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedParticipantsNamesArray))
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                                           containerViewModel: containerViewModel,
                                                           callUseCase: callUseCase,
                                                           captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                           localVideoUseCase: MockCallLocalVideoUseCase(),
                                                           remoteVideoUseCase: remoteVideoUseCase,
                                                           chatRoomUseCase: chatRoomUseCase,
                                                           userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                                           userImageUseCase: MockUserImageUseCase(),
                                                           chatRoom: chatRoom,
                                                           call: call)
        
        viewModel.dispatch(.onViewLoaded)
        
        let addedParticipantsNames: [String] = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsAdded(let addedParticipantsNames):
                        continuation.resume(returning: addedParticipantsNames)
                    default:
                        break
                    }
                }
                
                viewModel.dispatch(.addParticipant(withHandle: 101))
            }
        }.value
        
        XCTAssertEqual(addedParticipantsNames, addedParticipantsNamesArray, "Added participants list must match")
    }
    
    func testAction_MultipleParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedParticipantsNamesArray = ["User1", "User2", "User3"]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedParticipantsNamesArray))
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                                           containerViewModel: containerViewModel,
                                                           callUseCase: callUseCase,
                                                           captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                           localVideoUseCase: MockCallLocalVideoUseCase(),
                                                           remoteVideoUseCase: remoteVideoUseCase,
                                                           chatRoomUseCase: chatRoomUseCase,
                                                           userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                                           userImageUseCase: MockUserImageUseCase(),
                                                           chatRoom: chatRoom,
                                                           call: call)
        
        viewModel.dispatch(.onViewLoaded)
        let addedParticipantsNames: [String] = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsAdded(let addedParticipantsNames):
                        continuation.resume(returning: addedParticipantsNames)
                    default:
                        break
                    }
                }
                
                viewModel.dispatch(.addParticipant(withHandle: 101))
                viewModel.dispatch(.addParticipant(withHandle: 102))
                viewModel.dispatch(.addParticipant(withHandle: 103))
            }
        }.value
        
        XCTAssertEqual(addedParticipantsNames, addedParticipantsNamesArray, "Added participants list must match")
    }
    
    func testAction_singleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let removedParticipantsNamesArray = ["User1"]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(removedParticipantsNamesArray))
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                                           containerViewModel: containerViewModel,
                                                           callUseCase: callUseCase,
                                                           captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                           localVideoUseCase: MockCallLocalVideoUseCase(),
                                                           remoteVideoUseCase: remoteVideoUseCase,
                                                           chatRoomUseCase: chatRoomUseCase,
                                                           userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                                           userImageUseCase: MockUserImageUseCase(),
                                                           chatRoom: chatRoom,
                                                           call: call)
        
        viewModel.dispatch(.onViewLoaded)
        let removedParticipantsNames: [String] = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsRemoved(let removedParticipantsNames):
                        continuation.resume(returning: removedParticipantsNames)
                    default:
                        break
                    }
                }
                
                viewModel.dispatch(.removeParticipant(withHandle: 101))
            }
        }.value
        
        XCTAssertEqual(removedParticipantsNames, removedParticipantsNamesArray, "Removed participant list must match")
    }
    
    func testAction_MultipleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let removedParticipantsNamesArray = ["User1", "User2", "User3"]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(removedParticipantsNamesArray))
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                                           containerViewModel: containerViewModel,
                                                           callUseCase: callUseCase,
                                                           captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                           localVideoUseCase: MockCallLocalVideoUseCase(),
                                                           remoteVideoUseCase: remoteVideoUseCase,
                                                           chatRoomUseCase: chatRoomUseCase,
                                                           userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                                           userImageUseCase: MockUserImageUseCase(),
                                                           chatRoom: chatRoom,
                                                           call: call)
        
        viewModel.dispatch(.onViewLoaded)
        let removedParticipantsNames: [String] = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsRemoved(let removedParticipantsNames):
                        continuation.resume(returning: removedParticipantsNames)
                    default:
                        break
                    }
                }
                
                viewModel.dispatch(.removeParticipant(withHandle: 101))
                viewModel.dispatch(.removeParticipant(withHandle: 102))
                viewModel.dispatch(.removeParticipant(withHandle: 103))
            }
        }.value
        
        XCTAssertEqual(removedParticipantsNames, removedParticipantsNamesArray, "Removed participant list must match")
    }
    
    func testAction_oneParticipantsRemovedAndAddedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedParticipantsArray = ["User1"]
        let removedParticipantsArray = ["User2"]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedParticipantsArray + removedParticipantsArray))
        let containerViewModel = MeetingContainerViewModel(router: MockMeetingContainerRouter(), chatRoom: chatRoom, call: call, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase, callManagerUseCase: MockCallManagerUseCase(), userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false), authUseCase: MockAuthUseCase(isUserLoggedIn: true))
        
        let viewModel = MeetingParticipantsLayoutViewModel(router: MockCallViewRouter(),
                                                           containerViewModel: containerViewModel,
                                                           callUseCase: callUseCase,
                                                           captureDeviceUseCase: MockCaptureDeviceUseCase(),
                                                           localVideoUseCase: MockCallLocalVideoUseCase(),
                                                           remoteVideoUseCase: remoteVideoUseCase,
                                                           chatRoomUseCase: chatRoomUseCase,
                                                           userUseCase: MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
                                                           userImageUseCase: MockUserImageUseCase(),
                                                           chatRoom: chatRoom,
                                                           call: call)
        
        viewModel.dispatch(.onViewLoaded)
        
        let participantNames: ([String], [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantNames, let removedParticipantNames):
                        continuation.resume(returning: (addedParticipantNames, removedParticipantNames))
                    default:
                        break
                    }
                }
                
                viewModel.dispatch(.addParticipant(withHandle: 101))
                viewModel.dispatch(.removeParticipant(withHandle: 102))
            }
        }.value
        
        XCTAssertEqual(participantNames.0, addedParticipantsArray, "Added participant list must match")
        XCTAssertEqual(participantNames.1, removedParticipantsArray, "Removed participant list must match")
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
