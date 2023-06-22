@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    func testAction_onViewLoaded() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        test(viewModel: viewModel, action: .tapOnView(onParticipantsView: false), expectedCommands: [.switchMenusVisibility])
    }
    
    func testAction_tapOnLayoutButton() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: handleNamePairArray.count,
                                                      removedParticipantCount: 0,
                                                      addedParticipantNames: handleNamePairArray.map(\.name),
                                                      removedParticipantNames: [],
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_TwoParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: handleNamePairArray.count,
                                                      removedParticipantCount: 0,
                                                      addedParticipantNames: handleNamePairArray.map(\.name),
                                                      removedParticipantNames: [],
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_MultipleParticipantsAdded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2"), (103, "User3"), (104, "User4")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: handleNamePairArray.count,
                                                      removedParticipantCount: 0,
                                                      addedParticipantNames: Array(handleNamePairArray.map(\.name).prefix(1)),
                                                      removedParticipantNames: [],
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_singleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: 0,
                                                      removedParticipantCount: handleNamePairArray.count,
                                                      addedParticipantNames: [],
                                                      removedParticipantNames: handleNamePairArray.map(\.name),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_TwoParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: 0,
                                                      removedParticipantCount: handleNamePairArray.count,
                                                      addedParticipantNames: [],
                                                      removedParticipantNames: handleNamePairArray.map(\.name),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_MultipleParticipantsRemoved() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let handleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2"), (103, "User3"), (104, "User4"), (105, "User5")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(handleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(addedParticipantCount: 0,
                                                      removedParticipantCount: handleNamePairArray.count,
                                                      addedParticipantNames: [],
                                                      removedParticipantNames: Array(handleNamePairArray.map(\.name).prefix(1)),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_SingleParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1")]
        let removedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(103, "User1")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(addedParticipantCount: 1,
                                                      removedParticipantCount: 1,
                                                      addedParticipantNames: addedHandleNamePairArray.map(\.name),
                                                      removedParticipantNames: removedHandleNamePairArray.map(\.name),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_TwoParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2")]
        let removedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(103, "User1"), (104, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(addedParticipantCount: addedHandleNamePairArray.count,
                                                      removedParticipantCount: removedHandleNamePairArray.count,
                                                      addedParticipantNames: addedHandleNamePairArray.map(\.name),
                                                      removedParticipantNames: removedHandleNamePairArray.map(\.name),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testAction_MultipleParticipantsAddedAndRemovedAtTheSameTime() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let addedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(101, "User1"), (102, "User2"), (103, "User1"), (104, "User2")]
        let removedHandleNamePairArray: [(handle: HandleEntity, name: String)] = [(105, "User1"), (106, "User2"), (107, "User1"), (108, "User2")]
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success(addedHandleNamePairArray + removedHandleNamePairArray))
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase, chatRoomUseCase: chatRoomUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        viewModel.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: viewModel,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(addedParticipantCount: addedHandleNamePairArray.count,
                                                      removedParticipantCount: removedHandleNamePairArray.count,
                                                      addedParticipantNames: Array(addedHandleNamePairArray.map(\.name).prefix(1)),
                                                      removedParticipantNames: Array(removedHandleNamePairArray.map(\.name).prefix(1)),
                                                      isOnlyMyselfRemainingInTheCall: false)
        )
    }
    
    func testCallback_outgoingRingingStop_hangOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        let call = CallEntity(numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
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
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        callUseCase.callbacksDelegate = viewModel
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callUseCase.hangCall_CalledTimes == 0)
    }
    
    func testAction_participantAdded_createAvatar() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("test"), userDisplayNamesForPeersResult: .success([(handle: 100, name: "test")]))
        let expectation = expectation(description: "Awaiting publisher")
        let userUseCase = MockUserImageUseCase(result: .success(UIImage()), createAvatarCompletion: { handle in
            XCTAssert(handle == 100, "handle should match")
            expectation.fulfill()
        })
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: userUseCase,
            chatRoom: chatRoom,
            call: call
        )
        viewModel.participantJoined(participant: CallParticipantEntity(participantId: 100))
        userUseCase.avatarChangePublisher.send([100])
        waitForExpectations(timeout: 20)
    }
    
    func testAction_participantAdded_downloadAvatar() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let chatRoomUseCase = MockChatRoomUseCase()
        let chatRoomuserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("test"), userDisplayNamesForPeersResult: .success([(handle: 100, name: "test")]))
        let expectation = expectation(description: "Awaiting publisher")
        let userUseCase = MockUserImageUseCase(result: .success(UIImage()), downloadAvatarCompletion: { handle in
            XCTAssert(handle == 100, "handle should match")
            expectation.fulfill()
        })
        
        let viewModel = MeetingParticipantsLayoutViewModel(
            router: MockCallViewRouter(),
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomuserUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: userUseCase,
            chatRoom: chatRoom,
            call: call
        )
        viewModel.participantJoined(participant: CallParticipantEntity(participantId: 100))
        userUseCase.avatarChangePublisher.send([100])
        waitForExpectations(timeout: 20)
    }
    
    private func verifyParticipantsStatus(viewModel: MeetingParticipantsLayoutViewModel, actions: [CallViewAction], relaysCommand: MeetingParticipantsLayoutViewModel.Command) async {
        let nameExpectation = expectation(description: "Wait for names fetching task")
        let commandExpectation = expectation(description: "Relays command")
        viewModel.invokeCommand = { command in
            if command == relaysCommand {
                commandExpectation.fulfill()
            }
        }
        
        for action in actions {
            viewModel.dispatch(action)
        }
        
        _ = await XCTWaiter.fulfillment(of: [nameExpectation], timeout: 2)
        await viewModel.namesFetchingTask?.value
        await fulfillment(of: [commandExpectation], timeout: 1.0)
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
