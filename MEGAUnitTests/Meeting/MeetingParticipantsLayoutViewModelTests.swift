import CombineSchedulers
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    func testAction_onViewLoaded() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        
        test(viewModel: harness.sut,
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
        
        let harness = Harness(
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
        
        test(viewModel: harness.sut,
             action: .onViewLoaded,
             expectedCommands: [
                .configView(title: chatRoom.title ?? "", subtitle: "", isUserAGuest: false, isOneToOne: false),
                .updateHasLocalAudio(false)
             ])
        XCTAssert(callUseCase.startListeningForCall_CalledTimes == 1)
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssert(callUseCase.createActiveSessions_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func testAction_onViewReady_localUserHasRaisedHand() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(raiseHandsList: [100])
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
            containerViewModel: containerViewModel,
            callUseCase: callUseCase, 
            chatUseCase: MockChatUseCase(myUserHandle: 100),
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        test(viewModel: harness.sut,
             action: .onViewReady,
             expectedCommands: [
                .configLocalUserView(position: .front),
                .updateLocalRaisedHandHidden(false)
             ])
    }
    
    func testAction_onViewReady_localUserHasNotRaisedHand() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            chatUseCase: MockChatUseCase(myUserHandle: 100),
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            chatRoom: chatRoom,
            call: call
        )
        
        test(viewModel: harness.sut,
             action: .onViewReady,
             expectedCommands: [
                .configLocalUserView(position: .front),
                .updateLocalRaisedHandHidden(true)
             ])
    }
    
    func testAction_tapOnView() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        
        test(
            viewModel: harness.sut,
            action: .tapOnView(onParticipantsView: false),
            expectedCommands: [.switchMenusVisibility]
        )
    }
    
    func testAction_tapOnLayoutButton() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let harness = Harness(
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
        harness.sut.layoutMode = .grid
        test(
            viewModel: harness.sut,
             action: .tapOnLayoutModeButton,
             expectedCommands: [
                .switchLayoutMode(layout: .speaker, participantsCount: 0)
             ]
        )
    }
    
    func testAction_tapOnBackButton() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        harness.sut.layoutMode = .grid
        test(
            viewModel: harness.sut,
             action: .tapOnBackButton,
             expectedCommands: []
        )
        XCTAssert(remoteVideoUseCase.disableAllRemoteVideos_CalledTimes == 1)
    }
    
    func testAction_orientationOrModeChange_isIPhoneLandscape_inSpeakerMode() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        test(
            viewModel: harness.sut,
             action: .orientationOrModeChange(isIPhoneLandscape: true, isSpeakerMode: true),
             expectedCommands: [
                .configureSpeakerView(
                    isSpeakerMode: true,
                    leadingAndTrailingConstraint: 180,
                    topConstraint: 0,
                    bottomConstraint: 0
                )
             ]
        )
    }
    
    func testAction_orientationOrModeChange_noIPhoneLandscape_inSpeakerMode() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        test(
            viewModel: harness.sut,
             action: .orientationOrModeChange(isIPhoneLandscape: false, isSpeakerMode: true),
             expectedCommands: [
                .configureSpeakerView(
                    isSpeakerMode: true,
                    leadingAndTrailingConstraint: 0,
                    topConstraint: 160,
                    bottomConstraint: 200
                )
             ]
        )
    }
    
    func testAction_orientationOrModeChange_noIPhoneLandscape_noSpeakerMode() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        test(
            viewModel: harness.sut,
             action: .orientationOrModeChange(isIPhoneLandscape: false, isSpeakerMode: false),
             expectedCommands: [
                .configureSpeakerView(
                    isSpeakerMode: false,
                    leadingAndTrailingConstraint: 0,
                    topConstraint: 0,
                    bottomConstraint: 0
                )
             ]
        )
    }
    
    func testAction_orientationOrModeChange_isIPhoneLandscape_noSpeakerMode() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        test(
            viewModel: harness.sut,
             action: .orientationOrModeChange(isIPhoneLandscape: true, isSpeakerMode: false),
             expectedCommands: [
                .configureSpeakerView(
                    isSpeakerMode: false,
                    leadingAndTrailingConstraint: 0,
                    topConstraint: 0,
                    bottomConstraint: 0
                )
             ]
        )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: handleNamePairArray.count,
                removedParticipantCount: 0,
                addedParticipantNames: handleNamePairArray.map(\.name),
                removedParticipantNames: [],
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: handleNamePairArray.count,
                removedParticipantCount: 0,
                addedParticipantNames: handleNamePairArray.map(\.name),
                removedParticipantNames: [],
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .addParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: handleNamePairArray.count,
                removedParticipantCount: 0,
                addedParticipantNames: Array(handleNamePairArray.map(\.name).prefix(1)),
                removedParticipantNames: [],
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: 0,
                removedParticipantCount: handleNamePairArray.count,
                addedParticipantNames: [],
                removedParticipantNames: handleNamePairArray.map(\.name),
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: 0,
                removedParticipantCount: handleNamePairArray.count,
                addedParticipantNames: [],
                removedParticipantNames: handleNamePairArray.map(\.name),
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: handleNamePairArray.map { .removeParticipant(withHandle: $0.handle) },
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: 0,
                removedParticipantCount: handleNamePairArray.count,
                addedParticipantNames: [],
                removedParticipantNames: Array(handleNamePairArray.map(\.name).prefix(1)),
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: 1,
                removedParticipantCount: 1,
                addedParticipantNames: addedHandleNamePairArray.map(\.name),
                removedParticipantNames: removedHandleNamePairArray.map(\.name),
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: addedHandleNamePairArray.count,
                removedParticipantCount: removedHandleNamePairArray.count,
                addedParticipantNames: addedHandleNamePairArray.map(\.name),
                removedParticipantNames: removedHandleNamePairArray.map(\.name),
                isOnlyMyselfRemainingInTheCall: false
            )
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
        
        let harness = Harness(
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
        
        harness.sut.dispatch(.onViewLoaded)
        let addActions = addedHandleNamePairArray.map { CallViewAction.addParticipant(withHandle: $0.handle) }
        let removeActions = removedHandleNamePairArray.map { CallViewAction.removeParticipant(withHandle: $0.handle) }
        await verifyParticipantsStatus(
            viewModel: harness.sut,
            actions: addActions + removeActions,
            relaysCommand: .participantsStatusChanged(
                addedParticipantCount: addedHandleNamePairArray.count,
                removedParticipantCount: removedHandleNamePairArray.count,
                addedParticipantNames: Array(addedHandleNamePairArray.map(\.name).prefix(1)),
                removedParticipantNames: Array(removedHandleNamePairArray.map(\.name).prefix(1)),
                isOnlyMyselfRemainingInTheCall: false
            )
        )
    }
    
    func testCallback_outgoingRingingStop_hangOneToOne() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        let call = CallEntity(numberOfParticipants: 1)
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let callManager = MockCallManager()
        
        let harness = Harness(
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: MockChatRoomUseCase(),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: MockUserImageUseCase(),
            callManager: callManager,
            chatRoom: chatRoom,
            call: call
        )
        callUseCase.callbacksDelegate = harness.sut
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callManager.endCall_CalledTimes == 1)
    }
    
    func testCallback_outgoingRingingStop_doNotHangGroupCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
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
        callUseCase.callbacksDelegate = harness.sut
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
        
        let harness = Harness(
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
        callUseCase.callbacksDelegate = harness.sut
        callUseCase.outgoingRingingStopReceived()
        XCTAssert(callUseCase.hangCall_CalledTimes == 0)
    }
    
    func testAction_participantAdded_downloadAvatar() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity()
        let callUseCase = MockCallUseCase(call: call)
        callUseCase.chatRoom = chatRoom
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let chatRoomuserUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("test"), userDisplayNamesForPeersResult: .success([(handle: 100, name: "test")]))
        let expectation = expectation(description: "Awaiting publisher")
        let userUseCase = MockUserImageUseCase(downloadAvatarCompletion: { handle in
            XCTAssert(handle == "base64Handle", "handle should match")
            expectation.fulfill()
        })
        
        let harness = Harness(
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: MockCaptureDeviceUseCase(),
            localVideoUseCase: MockCallLocalVideoUseCase(),
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomuserUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            userImageUseCase: userUseCase,
            megaHandleUseCase: MockMEGAHandleUseCase(base64Handle: "base64Handle"),
            chatRoom: chatRoom,
            call: call
        )
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100))
        userUseCase.avatarChangePublisher.send([100])
        waitForExpectations(timeout: 20)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_onUpdateParticipantAndHasScreenSharingParticipant_shouldSwitchToSpeakerLayoutModeAndDisableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        harness.sut.updateParticipant(CallParticipantEntity(participantId: 100, hasScreenShare: true))
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_onParticipantJoinedAndHasScreenSharingParticipant_shouldSwitchToSpeakerLayoutModeAndDisableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: true))
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_onUpdateParticipantAndHasNoScreenSharingParticipant_shouldKeepCurrentLayoutModeAndEnableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        harness.sut.updateParticipant(CallParticipantEntity(participantId: 100, hasScreenShare: false))
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_onParticipantJoinedndHasScreenSharingParticipant_shouldKeepCurrentLayoutModeAndEnableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_onHasScreenShareAndThenUpdateToHasNoScreenShareParticipant_shouldSwitchToGridMode() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        let participant = CallParticipantEntity(participantId: 100, hasScreenShare: true)
        harness.sut.participantJoined(participant: participant)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        
        participant.hasScreenShare = false
        harness.sut.updateParticipant(participant)
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    func testUpdateLayoutModeAccordingScreenSharingParticipant_forTwoParticipantsAndOneHasScreenShareAndThenLeft_shouldSwitchToGridMode() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        let participant1 = CallParticipantEntity(participantId: 101, hasScreenShare: false)
        let participant2 = CallParticipantEntity(participantId: 102, hasScreenShare: true)
        harness.sut.participantJoined(participant: participant1)
        harness.sut.participantJoined(participant: participant2)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        
        harness.sut.participantLeft(participant: participant2)
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInHighResolutionAndHasCamera_shouldCallEnabledRemoteVideoWithHighResolution() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(
            participantId: 100,
            isVideoHiRes: true,
            canReceiveVideoHiRes: false,
            hasCamera: true,
            hasScreenShare: true
        )
        harness.sut.participantJoined(participant: participant)
        participant.canReceiveVideoHiRes = true
        harness.sut.highResolutionChanged(for: participant)
        
        XCTAssertEqual(remoteVideoUseCase.enableRemoteVideo_CalledTimes, 1)
    }
    
    func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInHighResolutionAndHasCameraAndIsReceivingHiResVideo_shouldNotCallEnabledRemoteVideoWithHighResolution() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(
            participantId: 100,
            isVideoHiRes: true,
            canReceiveVideoHiRes: false,
            hasCamera: true,
            hasScreenShare: true
        )
        harness.sut.participantJoined(participant: participant)
        participant.canReceiveVideoHiRes = true
        participant.isReceivingHiResVideo = true
        harness.sut.highResolutionChanged(for: participant)
        
        XCTAssertEqual(remoteVideoUseCase.enableRemoteVideo_CalledTimes, 0)
    }
    
    func testRequestRemoteScreenShareVideo_forParticipantHasScreenShareAndHasHighResVideo_shouldCallRequestHighResolutionVideo() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(participantId: 100, video: .on, isVideoHiRes: true, hasScreenShare: true)
        harness.sut.dispatch(.participantIsVisible(participant, index: 0))
        
        XCTAssertEqual(remoteVideoUseCase.requestHighResolutionVideo_calledTimes, 1)
    }
    
    func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInLowResolution_shouldCallEnabledRemoteVideoWithLowResolution() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(participantId: 100, isVideoLowRes: true, canReceiveVideoLowRes: false, hasCamera: true, hasScreenShare: true)
        harness.sut.participantJoined(participant: participant)
        participant.canReceiveVideoLowRes = true
        harness.sut.lowResolutionChanged(for: participant)
        
        XCTAssertEqual(remoteVideoUseCase.enableRemoteVideo_CalledTimes, 1)
    }
    
    func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInLowResolutionAndIsReceivingLowResVideo_shouldNotCallEnabledRemoteVideoWithLowResolution() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(
            participantId: 100,
            isVideoLowRes: true,
            canReceiveVideoLowRes: false,
            hasCamera: true,
            hasScreenShare: true
        )
        harness.sut.participantJoined(participant: participant)
        participant.canReceiveVideoLowRes = true
        participant.isReceivingLowResVideo = true
        harness.sut.lowResolutionChanged(for: participant)
        
        XCTAssertEqual(remoteVideoUseCase.enableRemoteVideo_CalledTimes, 0)
    }
    
    func testRequestRemoteScreenShareVideo_forParticipantHasScreenShareAndHasLowResVideoAndHasCamera_shouldCallRequestLowResolutionVideo() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(participantId: 100, video: .on, isVideoLowRes: true, hasCamera: true, hasScreenShare: true)
        harness.sut.dispatch(.participantIsVisible(participant, index: 0))
        
        XCTAssertEqual(remoteVideoUseCase.requestLowResolutionVideo_calledTimes, 1)
    }
    
    func testTapParticipantToPinAsSpeaker_forParticipantVideoOnAndHasScreenShareAndIsOnlyReceivingLowResVideo_shouldSwitchVideoResolutionLowToHigh() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase(
            stopLowResolutionVideoCompletion: .success,
            isOnlyReceivingLowResVideo: true
        )
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant1 = CallParticipantEntity(participantId: 101, hasScreenShare: true)
        let participant2 = CallParticipantEntity(participantId: 102, hasScreenShare: true)
        harness.sut.participantJoined(participant: participant1)
        harness.sut.participantJoined(participant: participant2)
        
        let newParticipant = CallParticipantEntity(participantId: 102, video: .on, hasScreenShare: true)
        harness.sut.dispatch(.tapParticipantToPinAsSpeaker(newParticipant))
        
        XCTAssertEqual(remoteVideoUseCase.stopLowResolutionVideo_calledTimes, 1)
        XCTAssertEqual(remoteVideoUseCase.requestHighResolutionVideo_calledTimes, 1)
    }
    
    func testAction_switchToSpeakerView_shouldPinFirstParticipantAsSpeaker() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.layoutMode = .speaker
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, true)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, true)
        XCTAssertEqual(harness.sut.speakerParticipant, firstParticipant)
    }
    
    func testAction_switchToGridView_shouldUnpinSpeaker() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.layoutMode = .speaker
        harness.sut.layoutMode = .grid

        XCTAssertEqual(harness.sut.layoutMode, .grid)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, false)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, false)
        XCTAssertEqual(harness.sut.speakerParticipant, nil)
    }
    
    func testCallBack_participantAudioLevelDetectedInGridMode_shouldUpdateAudioDetectedAndNoSetAsSpeakerPartipant() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        harness.sut.participantJoined(participant: firstParticipant)
        firstParticipant.audioDetected = true
        harness.sut.audioLevel(for: firstParticipant)
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, false)
        XCTAssertEqual(firstParticipant.audioDetected, true)
        XCTAssertEqual(harness.sut.speakerParticipant, nil)
    }
    
    func testCallBack_participantAudioLevelDetectedInSpeakerModeAndOtherParticipantPinned_shouldUpdateAudioDetectedAndNoSetAsSpeakerPartipant() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        secondParticipant.audioDetected = true
        harness.sut.audioLevel(for: secondParticipant)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, true)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, true)
        XCTAssertEqual(secondParticipant.isSpeakerPinned, false)
        XCTAssertEqual(secondParticipant.audioDetected, true)
        XCTAssertEqual(harness.sut.speakerParticipant, firstParticipant)
    }
    
    func testCallBack_participantAudioLevelDetectedInSpeakerModeAndNoOtherParticipantPinned_shouldUpdateAudioDetectedAndSetAsSpeakerPartipant() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        
        harness.sut.tappedParticipant(firstParticipant)

        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, false)
        XCTAssertEqual(harness.sut.speakerParticipant, nil)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, false)

        secondParticipant.audioDetected = true
        harness.sut.audioLevel(for: secondParticipant)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, false)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, false)
        XCTAssertEqual(secondParticipant.isSpeakerPinned, false)
        XCTAssertEqual(secondParticipant.audioDetected, true)
        XCTAssertEqual(harness.sut.speakerParticipant, secondParticipant)
    }

    func testCallBack_participantPinnedAndAudioLevelDetectedInSpeakerMode_shouldUpdateAudioDetectedAndKeepAsSpeakerPartipant() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        
        harness.sut.tappedParticipant(secondParticipant)

        secondParticipant.audioDetected = true
        harness.sut.audioLevel(for: secondParticipant)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, true)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, false)
        XCTAssertEqual(secondParticipant.isSpeakerPinned, true)
        XCTAssertEqual(secondParticipant.audioDetected, true)
        XCTAssertEqual(harness.sut.speakerParticipant, secondParticipant)
    }
    
    func testConfigScreenShareParticipants_forFirstParticipantIsSharingScreenAndSecondParticipantIsSpeakerAndNotSharingScreen_shouldCreateScreenShareParticipantForTheFirstParticipantBeforePresenterView() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, hasScreenShare: true)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: false)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        harness.sut.tappedParticipant(secondParticipant)
        
        XCTAssertEqual(harness.sut.callParticipants.count, 3)
        XCTAssertEqual(harness.sut.callParticipants[0], firstParticipant)
        XCTAssertTrue(harness.sut.callParticipants[0].isScreenShareCell)
        XCTAssertEqual(harness.sut.callParticipants[1], firstParticipant)
        XCTAssertFalse(harness.sut.callParticipants[1].isScreenShareCell)
    }
    
    func testConfigScreenShareParticipants_forFirstParticipantIsSharingScreenAndSecondParticipantIsSpeakerAndIsSharingScreen_shouldCreateScreenShareParticipantForTheFirstParticipantBeforePresenterView() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, hasScreenShare: true)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: true)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        harness.sut.tappedParticipant(secondParticipant)
        
        XCTAssertEqual(harness.sut.callParticipants.count, 3)
        XCTAssertEqual(harness.sut.callParticipants[1], firstParticipant)
        XCTAssertTrue(harness.sut.callParticipants[1].isScreenShareCell)
        XCTAssertEqual(harness.sut.callParticipants[2], firstParticipant)
        XCTAssertFalse(harness.sut.callParticipants[2].isScreenShareCell)
    }
    
    func testUpdateParticipant_onStopScreenShareAndThereIsScreenSharingParticipent_theNextScreenSharingParticipantShouldBecomeSpeaker() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, hasScreenShare: true)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: true)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        harness.sut.tappedParticipant(secondParticipant)
        
        XCTAssertEqual(harness.sut.speakerParticipant, secondParticipant)
        
        let updatedParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: false)
        harness.sut.updateParticipant(updatedParticipant)
        
        XCTAssertEqual(harness.sut.speakerParticipant, firstParticipant)
    }
    
    func testUpdateParticipant_onStopScreenShareAndThereIsNoScreenSharingParticipent_theSpeakerShouldBeNil() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, hasScreenShare: false)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: true)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.layoutMode = .speaker
        harness.sut.tappedParticipant(secondParticipant)
        
        XCTAssertEqual(harness.sut.speakerParticipant, secondParticipant)
        
        let updatedParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: false)
        harness.sut.updateParticipant(updatedParticipant)
        
        XCTAssertNil(harness.sut.speakerParticipant)
    }
    
    func testTappedParticipant_onFirstScreenShareParticipantAndTapSecondAndThirdNonScreenSareParticipant_shouldNotUpdateFirstScreenShareParticipant() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, hasScreenShare: true)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, hasScreenShare: false)
        let thirdParticipant = CallParticipantEntity(participantId: 103, clientId: 3, hasScreenShare: false)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        harness.sut.participantJoined(participant: thirdParticipant)
        
        harness.sut.tappedParticipant(secondParticipant)
        
        XCTAssertEqual(harness.sut.speakerParticipant, secondParticipant)
        XCTAssertEqual(harness.sut.callParticipants[0], firstParticipant)
        XCTAssertTrue(harness.sut.callParticipants[0].isScreenShareCell)
        
        harness.sut.tappedParticipant(thirdParticipant)
        
        XCTAssertEqual(harness.sut.speakerParticipant, thirdParticipant)
        XCTAssertEqual(harness.sut.callParticipants[0], firstParticipant)
        XCTAssertTrue(harness.sut.callParticipants[0].isScreenShareCell)
    }
    
    func testCallUpdate_localUserRaiseHand() {
        let callUseCase = MockCallUseCase()
        let harness = Harness(
            callUseCase: callUseCase,
            chatUseCase: MockChatUseCase(myUserHandle: 100)
        )
        
        let exp0 = expectation(description: "updateLocalRaisedHandHidden")
        let exp1 = expectation(description: "updateSnackBar")
        
        harness.sut.invokeCommand = { command in
            switch command {
            case .updateLocalRaisedHandHidden(let hidden):
                XCTAssertFalse(hidden)
                exp0.fulfill()
            case .updateSnackBar(let snackBar):
                XCTAssertNil(snackBar)
                exp1.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [100]))

        wait(for: [exp0, exp1])
    }
    
    func testCallUpdate_localUserNotRaiseHand() {
        let callUseCase = MockCallUseCase()
        let harness = Harness(
            callUseCase: callUseCase,
            chatUseCase: MockChatUseCase(myUserHandle: 100)
        )
        
        let exp0 = expectation(description: "updateLocalRaisedHandHidden")
        let exp1 = expectation(description: "updateSnackBar")
        
        harness.sut.invokeCommand = { command in
            switch command {
            case .updateLocalRaisedHandHidden(let hidden):
                XCTAssertTrue(hidden)
                exp0.fulfill()
            case .updateSnackBar(let snackBar):
                XCTAssertNil(snackBar)
                exp1.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101, 32]))

        wait(for: [exp0, exp1])
    }
    
    func testCallUpdate_remoteUserRaiseHand() {
        let callUseCase = MockCallUseCase()
        let harness = Harness(
            callUseCase: callUseCase
        )
        
        let remoteUserRaiseHandExpectation = expectation(description: "remote user raise hand icon visible after onChatCallUpdate with remote user handle in the raise hands list")

        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, raisedHand: false)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, raisedHand: false)
        
        harness.sut.invokeCommand = { command in
            switch command {
            case .reloadParticipantRaisedHandAt(let index, let participants):
                XCTAssertTrue(participants[index].raisedHand)
                remoteUserRaiseHandExpectation.fulfill()
            default:
                break
            }
        }
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        
        XCTAssertFalse(harness.sut.callParticipants[0].raisedHand)

        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101]))

        wait(for: [remoteUserRaiseHandExpectation], timeout: 3)
    }
    
    func testCallUpdate_remoteUserLowHand() {
        let callUseCase = MockCallUseCase()
        let harness = Harness(
            scheduler: .immediate,
            callUseCase: callUseCase
        )

        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, name: "1", raisedHand: true)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, name: "2", raisedHand: false)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        
        var receiveCommands = [MeetingParticipantsLayoutViewModel.Command]()
        harness.sut.invokeCommand = { command in
            receiveCommands.append(command)
        }
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101]))
        guard
            case .reloadParticipantRaisedHandAt = receiveCommands[0],
            case .updateSnackBar(let snackBar) = receiveCommands[1],
            case .updateLocalRaisedHandHidden(let hidden) = receiveCommands[2]
        else {
            XCTFail("received incorrect commands")
            return
        }
        
        XCTAssertNotNil(snackBar)
        XCTAssertTrue(hidden)
        
        receiveCommands.removeAll()
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: []))
        
        guard
            case .reloadParticipantRaisedHandAt = receiveCommands[0],
            case .updateLocalRaisedHandHidden(let hidden) = receiveCommands[1]
        else {
            XCTFail("received incorrect commands")
            return
        }
        
        XCTAssertTrue(hidden)
            
    }
    
    class Harness {
        let sut: MeetingParticipantsLayoutViewModel
        init(
            containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
            scheduler: AnySchedulerOf<DispatchQueue> = .main,
            callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
            chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
            callSessionUseCase: some CallSessionUseCaseProtocol = MockCallSessionUseCase(),
            captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
            localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
            remoteVideoUseCase: some CallRemoteVideoUseCaseProtocol = MockCallRemoteVideoUseCase(),
            chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
            chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
            accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
            userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
            analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
            megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
            callManager: some CallManagerProtocol = MockCallManager(),
            featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
            chatRoom: ChatRoomEntity = ChatRoomEntity(),
            call: CallEntity = CallEntity(),
            preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
            cameraSwitcher: some CameraSwitching = MockCameraSwitcher()
        ) {
            self.sut = .init(
                containerViewModel: containerViewModel,
                scheduler: scheduler,
                chatUseCase: chatUseCase,
                callUseCase: callUseCase,
                callSessionUseCase: callSessionUseCase,
                captureDeviceUseCase: captureDeviceUseCase,
                localVideoUseCase: localVideoUseCase,
                remoteVideoUseCase: remoteVideoUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                accountUseCase: accountUseCase,
                userImageUseCase: userImageUseCase,
                analyticsEventUseCase: analyticsEventUseCase,
                megaHandleUseCase: megaHandleUseCase,
                callManager: callManager,
                featureFlagProvider: featureFlagProvider,
                chatRoom: chatRoom,
                call: call,
                preferenceUseCase: preferenceUseCase,
                layoutUpdateChannel: .init(),
                cameraSwitcher: cameraSwitcher
            )
        }
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
