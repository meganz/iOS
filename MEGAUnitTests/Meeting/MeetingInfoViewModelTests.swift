import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class MeetingInfoViewModelTests: XCTestCase {
    func testShowWaitingRoomWarningBanner_givenModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOn_shouldBeFalse() {
        let chatRoom =  ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let sut = MeetingInfoViewModel(chatRoomUseCase: chatRoomUseCase)
        
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
    
    func testShowWaitingRoomWarningBanner_givenDismissedAndModeratorAndWaitingRoomOffThenOnAndAllowNonHostToAddParticipantsOn_shouldBeFalseThenTrue() {
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
    
    func testShowWaitingRoomWarningBanner_givenDismissedAndModeratorAndWaitingRoomOnAndAllowNonHostToAddParticipantsOffThenOn_shouldBeFalseThenTrue() {
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
    
    // MARK: - Private methods.
    
    private func evaluate(isInverted: Bool = false, expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        wait(for: [expectation], timeout: 5)
    }
}
