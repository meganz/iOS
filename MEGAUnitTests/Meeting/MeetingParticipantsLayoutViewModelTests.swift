import XCTest
@testable import MEGA

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    func testAction_onViewLoaded() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        
        let addedParticipantResult: (addedParticipantCount: Int,
                                     addedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount, _ , let addedParticipantNames, _, _):
                        continuation.resume(returning: (addedParticipantCount: addedParticipantCount, addedParticipantNames: addedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(addedParticipantResult.addedParticipantCount, handleNamePairArray.count, "Added participants count must match")
        XCTAssertEqual(addedParticipantResult.addedParticipantNames, handleNamePairArray.map(\.name), "Added participants list must match")
    }
    
    func testAction_TwoParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        
        let addedParticipantResult: (addedParticipantCount: Int,
                                     addedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount, _ , let addedParticipantNames, _, _):
                        continuation.resume(returning: (addedParticipantCount: addedParticipantCount, addedParticipantNames: addedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(addedParticipantResult.addedParticipantCount, handleNamePairArray.count, "Added participants count must match")
        XCTAssertEqual(addedParticipantResult.addedParticipantNames, handleNamePairArray.map(\.name), "Added participants list must match")
    }
    
    func testAction_MultipleParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2"), (103, "User3"), (104, "User4")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        
        let addedParticipantResult: (addedParticipantCount: Int,
                                     addedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount, _ , let addedParticipantNames, _, _):
                        continuation.resume(returning: (addedParticipantCount: addedParticipantCount, addedParticipantNames: addedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(addedParticipantResult.addedParticipantCount, handleNamePairArray.count, "Added participants count must match")
        XCTAssertEqual(addedParticipantResult.addedParticipantNames, Array(handleNamePairArray.map(\.name).prefix(1)), "Only first participant name must be returned")
    }
    
    func testAction_singleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let removedParticipantResult: (removedParticipantCount: Int,
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(_ , let removedParticipantCount , _, let removedParticipantNames, _):
                        continuation.resume(returning: (removedParticipantCount: removedParticipantCount, removedParticipantNames: removedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(removedParticipantResult.removedParticipantCount, handleNamePairArray.count, "Removed participants count must match")
        XCTAssertEqual(removedParticipantResult.removedParticipantNames, handleNamePairArray.map(\.name), "Removed participants list must match")
    }
    
    func testAction_TwoParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let removedParticipantResult: (removedParticipantCount: Int,
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(_ , let removedParticipantCount , _, let removedParticipantNames, _):
                        continuation.resume(returning: (removedParticipantCount: removedParticipantCount, removedParticipantNames: removedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(removedParticipantResult.removedParticipantCount, handleNamePairArray.count, "Removed participants count must match")
        XCTAssertEqual(removedParticipantResult.removedParticipantNames, handleNamePairArray.map(\.name), "Removed participants list must match")
    }
    
    func testAction_MultipleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2"), (103, "User3"), (104, "User4"), (105, "User5")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let removedParticipantResult: (removedParticipantCount: Int,
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(_ , let removedParticipantCount , _, let removedParticipantNames, _):
                        continuation.resume(returning: (removedParticipantCount: removedParticipantCount, removedParticipantNames: removedParticipantNames))
                    default:
                        break
                    }
                }
                
                handleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(removedParticipantResult.removedParticipantCount, handleNamePairArray.count, "Removed participants count must match")
        XCTAssertEqual(removedParticipantResult.removedParticipantNames, Array(handleNamePairArray.map(\.name).prefix(1)), "Only first participant name must be returned")
    }
    
    func testAction_SingleParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1")]
        let removedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(103, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let participantResult: (addedParticipantCount: Int,
                                       removedParticipantCount: Int,
                                       addedParticipantNames: [String],
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount,
                                                    let removedParticipantCount,
                                                    let addedParticipantNames,
                                                    let removedParticipantNames,
                                                    _):
                        continuation.resume(
                            returning: (addedParticipantCount: addedParticipantCount,
                                        removedParticipantCount: removedParticipantCount,
                                        addedParticipantNames: addedParticipantNames,
                                        removedParticipantNames: removedParticipantNames)
                        )
                    default:
                        break
                    }
                }
                
                addedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
                
                removedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(participantResult.addedParticipantCount, 1, "Added participants count must match")
        XCTAssertEqual(participantResult.removedParticipantCount, 1, "Removed participants count must match")
        XCTAssertEqual(participantResult.addedParticipantNames, addedHandleNamePairArray.map(\.name), "Participant name must be returned")
        XCTAssertEqual(participantResult.removedParticipantNames, removedHandleNamePairArray.map(\.name), "Participant name must be returned")
    }
    
    func testAction_TwoParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2")]
        let removedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(103, "User1"), (104, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let participantResult: (addedParticipantCount: Int,
                                       removedParticipantCount: Int,
                                       addedParticipantNames: [String],
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount,
                                                    let removedParticipantCount,
                                                    let addedParticipantNames,
                                                    let removedParticipantNames,
                                                    _):
                        continuation.resume(
                            returning: (addedParticipantCount: addedParticipantCount,
                                        removedParticipantCount: removedParticipantCount,
                                        addedParticipantNames: addedParticipantNames,
                                        removedParticipantNames: removedParticipantNames)
                        )
                    default:
                        break
                    }
                }
                
                addedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
                
                removedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(participantResult.addedParticipantCount, addedHandleNamePairArray.count, "Added participants count must match")
        XCTAssertEqual(participantResult.removedParticipantCount, removedHandleNamePairArray.count, "Removed participants count must match")
        XCTAssertEqual(participantResult.addedParticipantNames, addedHandleNamePairArray.map(\.name), "Participant name must be returned")
        XCTAssertEqual(participantResult.removedParticipantNames, removedHandleNamePairArray.map(\.name), "Participant name must be returned")
    }
    
    func testAction_MultipleParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(101, "User1"), (102, "User2"), (103, "User1"), (104, "User2")]
        let removedHandleNamePairArray: [(handle: MEGAHandle, name: String)] = [(105, "User1"), (106, "User2"), (107, "User1"), (108, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase(userDisplayNamesCompletion: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
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
        let participantResult: (addedParticipantCount: Int,
                                       removedParticipantCount: Int,
                                       addedParticipantNames: [String],
                                       removedParticipantNames: [String]) = try await TimeoutTask(duration: 10) {
            await withCheckedContinuation { continuation in
                viewModel.invokeCommand = { command in
                    switch command {
                    case .participantsStatusChanged(let addedParticipantCount,
                                                    let removedParticipantCount,
                                                    let addedParticipantNames,
                                                    let removedParticipantNames,
                                                    _ ):
                        continuation.resume(
                            returning: (addedParticipantCount: addedParticipantCount,
                                        removedParticipantCount: removedParticipantCount,
                                        addedParticipantNames: addedParticipantNames,
                                        removedParticipantNames: removedParticipantNames)
                        )
                    default:
                        break
                    }
                }
                
                addedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.addParticipant(withHandle: handleNamePair.handle))
                }
                
                removedHandleNamePairArray.forEach { handleNamePair in
                    viewModel.dispatch(.removeParticipant(withHandle: handleNamePair.handle))
                }
            }
        }.value
        
        XCTAssertEqual(participantResult.addedParticipantCount, addedHandleNamePairArray.count, "Added participants count must match")
        XCTAssertEqual(participantResult.removedParticipantCount, removedHandleNamePairArray.count, "Removed participants count must match")
        XCTAssertEqual(participantResult.addedParticipantNames, Array(addedHandleNamePairArray.map(\.name).prefix(1)), "Participant name must be returned")
        XCTAssertEqual(participantResult.removedParticipantNames, Array(removedHandleNamePairArray.map(\.name).prefix(1)), "Participant name must be returned")
    }
    
    func testCallback_outgoingRingingStop_hangOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        let call = CallEntity(numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        callUseCase.callbacksDelegate = viewModel
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callUseCase.hangCall_CalledTimes == 1)
    }
    
    func testCallback_outgoingRingingStop_doNotHangGroupCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        callUseCase.callbacksDelegate = viewModel
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callUseCase.hangCall_CalledTimes == 0)
    }
    
    func testCallback_outgoingRingingStop_doNotHangMeeting() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
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
        callUseCase.callbacksDelegate = viewModel
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callUseCase.hangCall_CalledTimes == 0)
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
    
    func startCallEndCountDownTimer() {}
    
    func endCallEndCountDownTimer() {}
}
