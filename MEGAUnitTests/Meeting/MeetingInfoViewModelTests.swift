import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class MeetingInfoViewModelTests: XCTestCase {
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
    
    // MARK: - Private methods.
    
    private func evaluate(isInverted: Bool = false, expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        wait(for: [expectation], timeout: 5)
    }
}
