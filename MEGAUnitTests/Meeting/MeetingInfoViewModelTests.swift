import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGATest
import XCTest

final class MeetingInfoViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: true])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
    func testShowWaitingRoomWarningBanner_givenNotModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
    func testShowWaitingRoomWarningBanner_givenModeratorAndNotWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndNotAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
                
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
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
                
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
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
                
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
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
                
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    @MainActor
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
        let userImageUseCase = MockUserImageUseCase()
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
        
        await evaluateAsync {
            sut.chatRoomAvatarViewModel?.chatListItemAvatar != beforeChatListItemAvatar
        }
    }
}
