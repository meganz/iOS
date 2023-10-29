import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import XCTest

final class MeetingInfoViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: true])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenNotModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenModeratorAndNotWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndNotAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOffThenOnAndAllowNonHostToAddParticipantsOn_shouldBeFalseThenTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, waitingRoomEnabled: true)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.isWaitingRoomOn = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOffThenOn_shouldBeFalseThenTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, allowNonHostToAddParticipantsEnabled: true)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.isAllowNonHostToAddParticipantsOn = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndModeratorAndWaitingRoomOffThenOnAndAllowNonHostToAddParticipantsOn_shouldBeFalseThenTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, waitingRoomEnabled: true)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: true])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.isWaitingRoomOn = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOffThenOn_shouldBeFalseThenTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, allowNonHostToAddParticipantsEnabled: true)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: true])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.isAllowNonHostToAddParticipantsOn = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
    func testAllowNonHostToAddParticipantsValueChanged_toNewValueOn_shouldTrackEvent() async {
        let tracker = MockTracker()
        let chatRoom = ChatRoomEntity()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, allowNonHostToAddParticipantsEnabled: true)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
                
        await sut.allowNonHostToAddParticipantsValueChanged(to: true)
                
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                ScheduledMeetingSettingEnableOpenInviteButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testAllowNonHostToAddParticipantsValueChanged_toNewValueOff_shouldNotTrackEvent() async {
        let tracker = MockTracker()
        let chatRoom = ChatRoomEntity()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, allowNonHostToAddParticipantsEnabled: false)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
                
        await sut.allowNonHostToAddParticipantsValueChanged(to: false)
                
        tracker.assertTrackAnalyticsEventCalled(
            with: []
        )
    }
    
    @MainActor
    func testWaitingRoomValueChanged_toNewValueOn_shouldTrackEvent() async {
        let tracker = MockTracker()
        let chatRoom = ChatRoomEntity()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, waitingRoomEnabled: true)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
                
        await sut.waitingRoomValueChanged(to: true)
                
        tracker.assertTrackAnalyticsEventCalled(
            with: [
                WaitingRoomEnableButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testWaitingRoomValueChanged_toNewValueOff_shouldNotTrackEvent() async {
        let tracker = MockTracker()
        let chatRoom = ChatRoomEntity()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom, waitingRoomEnabled: false)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
                
        await sut.waitingRoomValueChanged(to: false)
                
        tracker.assertTrackAnalyticsEventCalled(
            with: []
        )
    }
    
    func testMonitorChatListItemUpdate_onChatRoomPeersChange_shouldUpdateChatRoomAvatarViewModel() async {
        let participantsUpdatedSubject = PassthroughSubject<ChatRoomEntity, Never>()
        let chatRoomUseCase = MockChatRoomUseCase(
            chatRoomEntity: ChatRoomEntity(
                chatId: 100,
                peerCount: 1,
                chatType: .group,
                peers: [
                    ChatRoomEntity.Peer(handle: 101, privilege: .standard)
                ]
            ),
            participantsUpdatedSubjectWithChatRoom: participantsUpdatedSubject
        )
        let chatRoomUserUseCase = MockChatRoomUserUseCase(
            userDisplayNamesForPeersResult: .success([(101, "Peer1")])
        )
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: "base64Handle")
        let userImageUseCase = MockUserImageUseCase(
            result: .success(UIImage(systemName: "folder") ?? UIImage())
        )
        let sut = MeetingInfoViewModel(
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase
        )

        await sut.chatRoomAvatarViewModel?.loadAvatar(isRightToLeftLanguage: false)
        let beforeChatListItemAvatar = sut.chatRoomAvatarViewModel?.chatListItemAvatar
        let newChatRoomEntity = ChatRoomEntity(
            chatId: 100,
            peerCount: 2,
            chatType: .group,
            peers: [
                ChatRoomEntity.Peer(handle: 101, privilege: .standard),
                ChatRoomEntity.Peer(handle: 102, privilege: .standard)
            ]
        )
        participantsUpdatedSubject.send(newChatRoomEntity)
        
        evaluate {
            sut.chatRoomAvatarViewModel?.chatListItemAvatar != beforeChatListItemAvatar
        }
    }
    
    // MARK: - Private methods.
    
    private func evaluate(isInverted: Bool = false, expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        wait(for: [expectation], timeout: 5)
    }
}
