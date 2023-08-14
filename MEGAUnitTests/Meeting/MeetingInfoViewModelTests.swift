import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class MeetingInfoViewModelTests: XCTestCase {
    func testShowWaitingRoomWarningBanner_givenNotDismissedAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeTrue() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: false])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)
                
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenNotDismissedAndNotModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: false])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)

        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenNotDismissedAndModeratorAndNotWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: false])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)

        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenNotDismissedAndModeratorAndWaitingRoomOnAndNotAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: false])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)

        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenDismissedAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let preferenceUseCase = MockPreferenceUseCase(dict: [.waitingRoomWarningBannerDismissed: true])
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase, preferenceUseCase: preferenceUseCase)

        evaluate(isInverted: true) {
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
