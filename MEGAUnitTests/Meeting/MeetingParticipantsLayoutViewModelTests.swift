import CombineSchedulers
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

class MeetingParticipantsLayoutViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewLoaded() {
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
                .showEmptyCallShareOptionsView(canInviteParticipants: true),
                .updateHasLocalAudio(false),
                .updateBarButtons
             ])
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewLoaded_activeCall() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .meeting)
        let call = CallEntity(clientSessions: [ChatSessionEntity(statusType: .inProgress, peerId: 1)])
        let callUseCase = MockCallUseCase(call: call)
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
        
        let harness = Harness(
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            remoteVideoUseCase: remoteVideoUseCase,
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
            chatRoom: chatRoom,
            call: call
        )
        
        let participant = CallParticipantEntity(participantId: 1)
        test(viewModel: harness.sut,
             action: .onViewLoaded,
             expectedCommands: [
                .configView(title: chatRoom.title ?? "", subtitle: "", isUserAGuest: false, isOneToOne: false),
                .removeEmptyCallShareOptionsView,
                .updateBarButtons,
                .updateParticipants([participant]),
                .disableSwitchLayoutModeButton(disable: false),
                .updateHasLocalAudio(false),
                .updateBarButtons,
                .updateParticipants([participant]),
                .disableSwitchLayoutModeButton(disable: false),
                .reloadParticipantAt(0, [participant]),
                .updateParticipants([participant]),
                .updatePageControl(1),
                .hideEmptyRoomMessage
             ])
        XCTAssert(remoteVideoUseCase.addRemoteVideoListener_CalledTimes == 1)
    }
    
    @MainActor func testAction_onViewReady_localUserHasRaisedHand() {
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
    
    @MainActor func testAction_onViewReady_localUserHasNotRaisedHand() {
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
    
    @MainActor func testAction_tapOnView() {
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
    
    @MainActor func testAction_tapOnLayoutButton() {
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
    
    @MainActor func testAction_tapOnBackButton() {
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
    
    @MainActor func testAction_orientationOrModeChange_isIPhoneLandscape_inSpeakerMode() {
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
    
    @MainActor func testAction_orientationOrModeChange_noIPhoneLandscape_inSpeakerMode() {
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
    
    @MainActor func testAction_orientationOrModeChange_noIPhoneLandscape_noSpeakerMode() {
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
    
    @MainActor func testAction_orientationOrModeChange_isIPhoneLandscape_noSpeakerMode() {
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor func testCallUpdate_outgoingRingingStop_isOneToOneAndJustMyself_callMustBeEnded() async {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        let expectation = expectation(description: "Call ended called expectation")
        let callManager = MockCallManager {
            expectation.fulfill()
        }
        let harness = Harness(callManager: callManager, chatRoom: chatRoom)
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(changeType: .outgoingRingingStop, numberOfParticipants: 1))
        await fulfillment(of: [expectation], timeout: 0.1)
        XCTAssert(harness.callManager.endCall_CalledTimes == 1)
    }
    
    @MainActor func testCallUpdate_outgoingRingingStop_isOneToOneAndBothInCall_callNotMustBeEnded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .oneToOne)
        let harness = Harness(chatRoom: chatRoom)
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(changeType: .outgoingRingingStop, numberOfParticipants: 2))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssert(harness.callManager.endCall_CalledTimes == 0)
    }
    
    @MainActor func testCallUpdate_outgoingRingingStop_isNotOneToOne_callNotMustBeEnded() async throws {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, chatType: .group)
        let harness = Harness(chatRoom: chatRoom)
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(changeType: .outgoingRingingStop, numberOfParticipants: 1))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssert(harness.callManager.endCall_CalledTimes == 0)
    }
    
    @MainActor func testAction_participantAdded_downloadAvatar() {
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
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_onUpdateParticipantAndHasScreenSharingParticipant_shouldSwitchToSpeakerLayoutModeAndDisableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        harness.sut.updateParticipant(CallParticipantEntity(participantId: 100, hasScreenShare: true))
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
    }
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_onParticipantJoinedAndHasScreenSharingParticipant_shouldSwitchToSpeakerLayoutModeAndDisableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: true))
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
    }
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_onUpdateParticipantAndHasNoScreenSharingParticipant_shouldKeepCurrentLayoutModeAndEnableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        harness.sut.updateParticipant(CallParticipantEntity(participantId: 100, hasScreenShare: false))
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_onParticipantJoinedndHasScreenSharingParticipant_shouldKeepCurrentLayoutModeAndEnableSwitchLayoutModeButton() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        harness.sut.participantJoined(participant: CallParticipantEntity(participantId: 100, hasScreenShare: false))
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_onHasScreenShareAndThenUpdateToHasNoScreenShareParticipant_shouldSwitchToGridMode() {
        let harness = Harness()
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
        
        let participant = CallParticipantEntity(participantId: 100, hasScreenShare: true)
        harness.sut.participantJoined(participant: participant)
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        
        let participantUpdated = CallParticipantEntity(participantId: 100, hasScreenShare: false)
        harness.sut.updateParticipant(participantUpdated)
        
        XCTAssertEqual(harness.sut.layoutMode, .grid)
    }
    
    @MainActor func testUpdateLayoutModeAccordingScreenSharingParticipant_forTwoParticipantsAndOneHasScreenShareAndThenLeft_shouldSwitchToGridMode() {
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
    
    @MainActor func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInHighResolutionAndHasCamera_shouldCallEnabledRemoteVideoWithHighResolution() {
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
    
    @MainActor func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInHighResolutionAndHasCameraAndIsReceivingHiResVideo_shouldNotCallEnabledRemoteVideoWithHighResolution() {
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
    
    @MainActor func testRequestRemoteScreenShareVideo_forParticipantHasScreenShareAndHasHighResVideo_shouldCallRequestHighResolutionVideo() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(participantId: 100, video: .on, isVideoHiRes: true, hasScreenShare: true)
        harness.sut.dispatch(.participantIsVisible(participant, index: 0))
        
        XCTAssertEqual(remoteVideoUseCase.requestHighResolutionVideo_calledTimes, 1)
    }
    
    @MainActor func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInLowResolution_shouldCallEnabledRemoteVideoWithLowResolution() {
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
    
    @MainActor func testEnableRemoteScreenShareVideo_forParticipantHasScreenShareAndCanReceiveVideoInLowResolutionAndIsReceivingLowResVideo_shouldNotCallEnabledRemoteVideoWithLowResolution() {
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
    
    @MainActor func testRequestRemoteScreenShareVideo_forParticipantHasScreenShareAndHasLowResVideoAndHasCamera_shouldCallRequestLowResolutionVideo() {
        let remoteVideoUseCase = MockCallRemoteVideoUseCase()
        let harness = Harness(
            remoteVideoUseCase: remoteVideoUseCase
        )
        
        let participant = CallParticipantEntity(participantId: 100, video: .on, isVideoLowRes: true, hasCamera: true, hasScreenShare: true)
        harness.sut.dispatch(.participantIsVisible(participant, index: 0))
        
        XCTAssertEqual(remoteVideoUseCase.requestLowResolutionVideo_calledTimes, 1)
    }
    
    @MainActor func testTapParticipantToPinAsSpeaker_forParticipantVideoOnAndHasScreenShareAndIsOnlyReceivingLowResVideo_shouldSwitchVideoResolutionLowToHigh() {
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
    
    @MainActor func testAction_switchToSpeakerView_shouldPinFirstParticipantAsSpeaker() {
        let harness = Harness()
        let firstParticipant = CallParticipantEntity(participantId: 100, clientId: 1)
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.layoutMode = .speaker
        
        XCTAssertEqual(harness.sut.layoutMode, .speaker)
        XCTAssertEqual(firstParticipant.isSpeakerPinned, true)
        XCTAssertEqual(harness.sut.isSpeakerParticipantPinned, true)
        XCTAssertEqual(harness.sut.speakerParticipant, firstParticipant)
    }
    
    @MainActor func testAction_switchToGridView_shouldUnpinSpeaker() {
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
    
    @MainActor func testCallBack_participantAudioLevelDetectedInGridMode_shouldUpdateAudioDetectedAndNoSetAsSpeakerPartipant() {
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
    
    @MainActor func testCallBack_participantAudioLevelDetectedInSpeakerModeAndOtherParticipantPinned_shouldUpdateAudioDetectedAndNoSetAsSpeakerPartipant() {
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
    
    @MainActor func testCallBack_participantAudioLevelDetectedInSpeakerModeAndNoOtherParticipantPinned_shouldUpdateAudioDetectedAndSetAsSpeakerPartipant() {
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

    @MainActor func testCallBack_participantPinnedAndAudioLevelDetectedInSpeakerMode_shouldUpdateAudioDetectedAndKeepAsSpeakerPartipant() {
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
    
    @MainActor func testConfigScreenShareParticipants_forFirstParticipantIsSharingScreenAndSecondParticipantIsSpeakerAndNotSharingScreen_shouldCreateScreenShareParticipantForTheFirstParticipantBeforePresenterView() {
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
    
    @MainActor func testConfigScreenShareParticipants_forFirstParticipantIsSharingScreenAndSecondParticipantIsSpeakerAndIsSharingScreen_shouldCreateScreenShareParticipantForTheFirstParticipantBeforePresenterView() {
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
    
    @MainActor func testUpdateParticipant_onStopScreenShareAndThereIsScreenSharingParticipent_theNextScreenSharingParticipantShouldBecomeSpeaker() {
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
    
    @MainActor func testUpdateParticipant_onStopScreenShareAndThereIsNoScreenSharingParticipent_theSpeakerShouldBeNil() {
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
    
    @MainActor func testTappedParticipant_onFirstScreenShareParticipantAndTapSecondAndThirdNonScreenSareParticipant_shouldNotUpdateFirstScreenShareParticipant() {
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
    
    @MainActor func testCallUpdate_localUserRaiseHand() async {
        let harness = Harness(
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
                XCTAssertNotNil(snackBar)
                exp1.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [100]))
        await fulfillment(of: [exp0, exp1], timeout: 3)
    }
    
    @MainActor func testCallUpdate_localUserNotRaiseHand() async {
        let harness = Harness(
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
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101, 32]))

        await fulfillment(of: [exp0, exp1], timeout: 3)
    }
    
    @MainActor func testCallUpdate_remoteUserRaiseHand() async {
        let harness = Harness()
        
        let remoteUserRaiseHandExpectation = expectation(description: "remote user raise hand icon visible after onChatCallUpdate with remote user handle in the raise hands list")

        let firstParticipant = CallParticipantEntity(participantId: 101, clientId: 1, raisedHand: false)
        let secondParticipant = CallParticipantEntity(participantId: 102, clientId: 2, raisedHand: false)
        
        harness.sut.invokeCommand = { command in
            switch command {
            case .updateParticipantRaisedHandAt(let index, _):
                XCTAssertTrue(harness.sut.callParticipants[index].raisedHand)
                remoteUserRaiseHandExpectation.fulfill()
            default:
                break
            }
        }
        harness.sut.participantJoined(participant: firstParticipant)
        harness.sut.participantJoined(participant: secondParticipant)
        
        XCTAssertFalse(harness.sut.callParticipants[0].raisedHand)

        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101]))

        await fulfillment(of: [remoteUserRaiseHandExpectation], timeout: 3)
    }
    
    @MainActor func testCallUpdate_remoteUserLowHand() async throws {
        let harness = Harness()

        harness.sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(statusType: .inProgress, peerId: 101, clientId: 1, changeType: .status), CallEntity()))
        harness.sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(statusType: .inProgress, peerId: 102, clientId: 2, changeType: .status), CallEntity()))
        
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: [101]))

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let remoteUserLowHandExpectation = expectation(description: "remote user low hand icon hidden after onChatCallUpdate without remote user handle in the raise hands list")
        let snackBarNilExpectation = expectation(description: "nil snack bar after user lower hand")

        harness.sut.invokeCommand = { command in
            switch command {
            case .updateParticipantRaisedHandAt(let index, _):
                XCTAssertFalse(harness.sut.callParticipants[index].raisedHand)
                remoteUserLowHandExpectation.fulfill()
            case .updateSnackBar(let snackBar):
                XCTAssertNil(snackBar)
                snackBarNilExpectation.fulfill()
            default:
                break
            }
        }
        
        harness.callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .callRaiseHand, raiseHandsList: []))
        
        await fulfillment(of: [remoteUserLowHandExpectation, snackBarNilExpectation], timeout: 1)
    }
        
    @MainActor final class Harness: Sendable {
        let scheduler: AnySchedulerOf<DispatchQueue>
        let callUpdateUseCase: MockCallUpdateUseCase
        let sessionUpdateUseCase: MockSessionUpdateUseCase
        let callManager: MockCallManager
        let sut: MeetingParticipantsLayoutViewModel
        init(
            containerViewModel: MeetingContainerViewModel? = nil,
            scheduler: AnySchedulerOf<DispatchQueue> = .main,
            callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
            chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
            captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
            localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
            remoteVideoUseCase: some CallRemoteVideoUseCaseProtocol = MockCallRemoteVideoUseCase(),
            chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
            chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
            accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
            userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
            analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
            megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
            callUpdateUseCase: MockCallUpdateUseCase = MockCallUpdateUseCase(),
            chatRoomUpdateUseCase: MockChatRoomUpdateUseCase = MockChatRoomUpdateUseCase(),
            sessionUpdateUseCase: MockSessionUpdateUseCase = MockSessionUpdateUseCase(),
            callManager: MockCallManager = MockCallManager(),
            featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
            chatRoom: ChatRoomEntity = ChatRoomEntity(),
            call: CallEntity = CallEntity(),
            preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
            cameraSwitcher: some CameraSwitching = MockCameraSwitcher()
        ) {
            self.scheduler = scheduler
            self.callUpdateUseCase = callUpdateUseCase
            self.sessionUpdateUseCase = sessionUpdateUseCase
            self.callManager = callManager
            self.sut = .init(
                containerViewModel: containerViewModel ?? MeetingContainerViewModel(),
                scheduler: scheduler,
                chatUseCase: chatUseCase,
                callUseCase: callUseCase,
                captureDeviceUseCase: captureDeviceUseCase,
                localVideoUseCase: localVideoUseCase,
                remoteVideoUseCase: remoteVideoUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                accountUseCase: accountUseCase,
                userImageUseCase: userImageUseCase,
                analyticsEventUseCase: analyticsEventUseCase,
                megaHandleUseCase: megaHandleUseCase,
                callUpdateUseCase: callUpdateUseCase,
                sessionUpdateUseCase: sessionUpdateUseCase,
                chatRoomUpdateUseCase: chatRoomUpdateUseCase,
                callManager: callManager,
                featureFlagProvider: featureFlagProvider,
                timerSequence: MockTimerSequenceFactory(),
                chatRoom: chatRoom,
                call: call,
                preferenceUseCase: preferenceUseCase,
                layoutUpdateChannel: .init(),
                cameraSwitcher: cameraSwitcher
            )
            
            sut.monitorOnCallUpdate()
            sut.monitorOnSessionUpdate()
            sut.monitorOnChatRoomUpdate()
        }
    }
    
    @MainActor
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
