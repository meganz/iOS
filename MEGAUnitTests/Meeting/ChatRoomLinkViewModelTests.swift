import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class ChatRoomLinkViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    @MainActor
    func testIsMeetingLinkOn_onReceiveMeetingLinkNoneNil_meetingLinkShouldBeOn() {
        let chatLinkUseCase = MockChatLinkUseCase(link: "Meeting link")
        
        let sut = makeChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
        let exp = expectation(description: "Should receive meeting link update")
        sut.$isMeetingLinkOn
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                exp.fulfill()
                subscriptions.removeAll()
            }
            .store(in: &subscriptions)
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(sut.isMeetingLinkOn)
    }
    
    @MainActor
    func testIsMeetingLinkOn_onReceiveMeetingLinkNil_meetingLinkShouldBeOff() {
        let chatLinkUseCase = MockChatLinkUseCase(link: nil)

        let sut = makeChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
        let exp = expectation(description: "Should receive meeting link update")
        sut.$isMeetingLinkOn
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                exp.fulfill()
                subscriptions.removeAll()
            }
            .store(in: &subscriptions)
        wait(for: [exp], timeout: 1)
        XCTAssertFalse(sut.isMeetingLinkOn)
    }

    @MainActor
    func testShareMeetingLinkTapped_onShareLinkTapped_shouldTrackEvent() {
        let tracker = MockTracker()
        let sut = makeChatRoomLinkViewModel(tracker: tracker)
        
        sut.shareMeetingLinkTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingShareMeetingLinkButtonEvent()
            ]
        )
    }
    
    // MARK: - Private

    @MainActor
    private func makeChatRoomLinkViewModel(
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        chatLinkUseCase: some ChatLinkUseCaseProtocol = MockChatLinkUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        subtitle: String = ""
    ) -> ChatRoomLinkViewModel {
        ChatRoomLinkViewModel(
            router: router,
            chatRoom: chatRoom,
            scheduledMeeting: scheduledMeeting,
            chatLinkUseCase: chatLinkUseCase,
            chatUseCase: chatUseCase,
            tracker: tracker,
            subtitle: subtitle
        )
    }
}

final class MockMeetingInfoRouter: MeetingInfoRouting {
    var showSharedFiles_calledTimes = 0
    var showManageChatHistory_calledTimes = 0
    var showEnableKeyRotation_calledTimes = 0
    var closeMeetingInfoView_calledTimes = 0
    var showLeaveChatAlert_calledTimes = 0
    var showShareActivity_calledTimes = 0
    var showSendToChat_calledTimes = 0
    var showLinkCopied_calledTimes = 0
    var showParticipantDetails_calledTimes = 0
    var inviteParticipants_calledTimes = 0
    var showAllContactsAlreadyAddedAlert_calledTimes = 0
    var showNoAvailableContactsAlert_calledTimes = 0
    var editMeeting_calledTimes = 0
    var editMeetingPublisher = PassthroughSubject<ScheduledMeetingEntity, Never>()
    var didUpdatePeerPermissionResult: ChatRoomParticipantPrivilege?
    
    nonisolated init() {}
    
    func showSharedFiles(for chatRoom: MEGADomain.ChatRoomEntity) {
        showSharedFiles_calledTimes += 1
    }
    
    func showManageChatHistory(for chatRoom: MEGADomain.ChatRoomEntity) {
        showManageChatHistory_calledTimes += 1
    }
    
    func showEnableKeyRotation(for chatRoom: MEGADomain.ChatRoomEntity) {
        showEnableKeyRotation_calledTimes += 1
    }
    
    func closeMeetingInfoView() {
        closeMeetingInfoView_calledTimes += 1
    }
    
    func showLeaveChatAlert(leaveAction: @escaping (() -> Void)) {
        showLeaveChatAlert_calledTimes += 1
    }
    
    func showShareMeetingLinkActivity(_ link: String, metadataItemSource: ChatLinkPresentationItemSource) {
        showShareActivity_calledTimes += 1
    }
    
    func sendLinkToChat(_ link: String) {
        showSendToChat_calledTimes += 1
    }
    
    func showLinkCopied() {
        showLinkCopied_calledTimes += 1
    }
    
    func showParticipantDetails(email: String, userHandle: MEGADomain.HandleEntity, chatRoom: MEGADomain.ChatRoomEntity, didUpdatePeerPermission: @escaping (ChatRoomParticipantPrivilege) -> Void) {
        showParticipantDetails_calledTimes += 1
        if let didUpdatePeerPermissionResult {
            didUpdatePeerPermission(didUpdatePeerPermissionResult)
        }
    }
    
    func inviteParticipants(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory, excludeParticipantsId: Set<HandleEntity>, selectedUsersHandler: @escaping (([HandleEntity]) -> Void)) {
        inviteParticipants_calledTimes += 1
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: MEGA.ParticipantsAddingViewFactory) {
        showAllContactsAlreadyAddedAlert_calledTimes += 1
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: MEGA.ParticipantsAddingViewFactory) {
        showNoAvailableContactsAlert_calledTimes += 1
    }
    
    func edit(meeting: ScheduledMeetingEntity) -> AnyPublisher<ScheduledMeetingEntity, Never> {
        editMeeting_calledTimes += 1
        return editMeetingPublisher.eraseToAnyPublisher()
    }
}
