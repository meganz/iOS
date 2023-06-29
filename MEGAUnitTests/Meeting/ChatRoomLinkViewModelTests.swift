import Combine
@testable import MEGA
import MEGADomain
import XCTest

final class ChatRoomLinkViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testIsMeetingLinkOn_onReceiveMeetingLinkNoneNil_meetingLinkShouldBeOn() {
        let chatLinkUseCase = MockChatLinkUseCase(link: "Meeting link")
        
        let sut = ChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
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
    
    func testIsMeetingLinkOn_onReceiveMeetingLinkNil_meetingLinkShouldBeOff() {
        let chatLinkUseCase = MockChatLinkUseCase(link: nil)

        let sut = ChatRoomLinkViewModel(chatLinkUseCase: chatLinkUseCase)
        
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
    
    func testMeetingLink_changeMeetingLinkToggleToOff_shouldNotBeAbleToShareMeetingLink() {
        let router = MockMeetingInfoRouter()
        let chatLinkUseCase = MockChatLinkUseCase(link: "Meeting link")
        let chatRoom = ChatRoomEntity(hasCustomTitle: true)

        let sut = ChatRoomLinkViewModel(router: router, chatRoom: chatRoom, chatLinkUseCase: chatLinkUseCase)
        
        let predicate = NSPredicate { _, _ in
            sut.isMeetingLinkOn == true
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 10)
        
        sut.isMeetingLinkOn = false
        
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 1) == .timedOut {
            sut.shareOptionTapped(.send)
            XCTAssertEqual(router.showSendToChat_calledTimes, 0)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func testMeetingLink_changeMeetingLinkToggleToOn_shouldBeAbleToShareMeetingLink() {
        let router = MockMeetingInfoRouter()
        let chatLinkUseCase = MockChatLinkUseCase(link: nil)
        let chatRoom = ChatRoomEntity(hasCustomTitle: true)
        
        let sut = ChatRoomLinkViewModel(router: router, chatRoom: chatRoom, chatLinkUseCase: chatLinkUseCase)
        
        let predicate = NSPredicate { _, _ in
            sut.isMeetingLinkOn == false
        }
        let exception = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [exception], timeout: 10)
        
        sut.isMeetingLinkOn = true
        
        let predicateShare = NSPredicate { _, _ in
            sut.shareOptionTapped(.send)
            return router.showSendToChat_calledTimes > 0
        }
        let exceptionShare = expectation(for: predicateShare, evaluatedWith: nil)
        wait(for: [exceptionShare], timeout: 10)
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
    
    func showShareActivity(_ link: String, title: String?, description: String?) {
        showShareActivity_calledTimes += 1
    }
    
    func showSendToChat(_ link: String) {
        showSendToChat_calledTimes += 1
    }
    
    func showLinkCopied() {
        showLinkCopied_calledTimes += 1
    }
    
    func showParticipantDetails(email: String, userHandle: MEGADomain.HandleEntity, chatRoom: MEGADomain.ChatRoomEntity) {
        showParticipantDetails_calledTimes += 1
    }
    
    func inviteParticipants(withParticipantsAddingViewFactory participantsAddingViewFactory: MEGA.ParticipantsAddingViewFactory, excludeParticpantsId: Set<MEGADomain.HandleEntity>, selectedUsersHandler: @escaping (([MEGADomain.HandleEntity]) -> Void)) {
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
