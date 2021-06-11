import XCTest
@testable import MEGA

final class MeetingCreateViewModelTests: XCTestCase {
    func testAction_onViewReady_createMeeting() {
        let router = MockMeetingCreateRouter()

        let viewModel = MeetingCreatingViewModel(
            router: router,
            type: .start,
            meetingUseCase: MockMeetingCreatingUseCase(),
            audioSessionUseCase: MockAudioSessionUseCase(),
            callsUseCase: MockCallsUseCase(),
            link: nil
        )
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .configView(title: "test name Meeting", subtitle: "", type: .start, isMicrophoneEnabled: true)
             ])
    }
    
    func testAction_onViewReady_joinMeeting() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: "test name Meeting", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: false, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)

        useCase.chatCallCompletion = .success(chatRoom)
        let viewModel = MeetingCreatingViewModel(
            router: router,
            type: .join,
            meetingUseCase: useCase,
            audioSessionUseCase: MockAudioSessionUseCase(),
            callsUseCase: MockCallsUseCase(),
            link: ""
        )
        
        test(viewModel: viewModel,
             action: .onViewReady,
             expectedCommands: [
                .loadingStartMeeting,
                .loadingEndMeeting,
                .configView(title: "test name Meeting", subtitle: "", type: .join, isMicrophoneEnabled: true)
             ])
    }
    
    func testAction_updateSpeakerButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let viewModel = MeetingCreatingViewModel(
            router: router,
            type: .join,
            meetingUseCase: useCase,
            audioSessionUseCase: MockAudioSessionUseCase(),
            callsUseCase: MockCallsUseCase(),
            link: ""
        )
        test(viewModel: viewModel,
             action: .didTapSpeakerButton,
             expectedCommands: [
                .updateSpeakerButton(enabled: true)
             ])
    }
    
    func testAction_didTapCloseButton() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let viewModel = MeetingCreatingViewModel(
            router: router,
            type: .join,
            meetingUseCase: useCase,
            audioSessionUseCase: MockAudioSessionUseCase(),
            callsUseCase: MockCallsUseCase(),
            link: ""
        )
        
        viewModel.dispatch(.didTapCloseButton)
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(useCase.releaseDevice_CalledTimes == 1)
    }
    
    func testAction_joinChatCall() {
        let router = MockMeetingCreateRouter()
        let useCase = MockMeetingCreatingUseCase()
        let chatRoom = ChatRoomEntity(chatId: 100, ownPrivilege: .standard, changeType: nil, peerCount: 0, authorizationToken: "", title: "test name Meeting", unreadCount: 0, userTypingHandle: 0, retentionTime: 0, creationTimeStamp: 0, isGroup: false, hasCustomTitle: false, isPublicChat: false, isPreview: false, isactive: false, isArchived: false, isMeeting: true)

        useCase.chatCallCompletion = .success(chatRoom)
        let viewModel = MeetingCreatingViewModel(
            router: router,
            type: .start,
            meetingUseCase: useCase,
            audioSessionUseCase: MockAudioSessionUseCase(),
            callsUseCase: MockCallsUseCase(),
            link: ""
        )
        
        viewModel.dispatch(.didTapStartMeetingButton)
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(router.goToMeetingRoom_calledTimes == 1)

    }
    
}

final class MockMeetingCreateRouter: MeetingCreatingViewRouting {
    var dismiss_calledTimes = 0
    var goToMeetingRoom_calledTimes = 0
    var openChatRoom_calledTimes = 0

    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool) {
        goToMeetingRoom_calledTimes += 1
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        openChatRoom_calledTimes += 1
    }
    
}
