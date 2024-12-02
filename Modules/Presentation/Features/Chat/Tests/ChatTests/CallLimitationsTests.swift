import Chat
import Combine
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

extension Int {
    static let testLimit = 10
}

@MainActor
final class CallLimitationsTests: XCTestCase {
    
    @MainActor
    class Harness {
        let sut: CallLimitations
        let callUpdateUseCase = MockCallUpdateUseCase()
        var subscriptions = Set<AnyCancellable>()
        var limitsUpdatedCount = 0
        init(
            initialLimit: Int = .testLimit,
            isModerator: Bool = false // this is not used using contactPickerLimitChecker
        ) {
            
            let ownPrivilege: ChatRoomPrivilegeEntity = if isModerator {
                .moderator
            } else {
                .unknown
            }
            
            sut = .init(
                initialLimit: initialLimit,
                chatRoom: ChatRoomEntity(ownPrivilege: ownPrivilege),
                callUpdateUseCase: callUpdateUseCase,
                chatRoomUseCase: MockChatRoomUseCase()
            )
            
            sut.limitsChangedPublisher
                .sink { [weak self] in
                    self?.limitsUpdatedCount += 1
                }
                .store(in: &subscriptions)
        }
        
        func callStarted(maxUsers: Int) {
            callUpdateUseCase.sendCallUpdate(
                .init(
                    status: .inProgress,
                    changeType: .status,
                    callLimits: .init(
                        durationLimit: -1,
                        maxUsers: maxUsers,
                        maxClientsPerUser: -1,
                        maxClients: -1
                    )
                )
            )
        }
    }
    
    func testCheckingInitialLimit_isNotModerator_limitIsNeverReached() {
        let harness = Harness(isModerator: false)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 999))
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 999,
            callParticipantsInWaitingRoom: 999)
        )
    }
    
    func testCheckingInitialLimit_isModerator_belowLimit() {
        let harness = Harness(initialLimit: 10, isModerator: true)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 9))
    }
    
    func testCheckingInitialLimit_isModerator_atLimit() {
        let harness = Harness(initialLimit: 10, isModerator: true)
        XCTAssertTrue(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 10))
    }
    
    func testCheckingInitialLimit_isModerator_aboveLimit() {
        let harness = Harness(initialLimit: 10, isModerator: true)
        XCTAssertTrue(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 11))
    }
    
    func testCheckingInitialLimit_TotalOfCallAndWaitingRoom_BelowLimit() {
        let harness = Harness(isModerator: true)
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 5,
            callParticipantsInWaitingRoom: 4)
        ) // 5 + 4 < 10
    }
    
    func testCheckingInitialLimit_TotalOfCallAndWaitingRoom_AboveLimit() {
        let harness = Harness(isModerator: true)
        XCTAssertTrue(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 5,
            callParticipantsInWaitingRoom: 6)
        ) // 5 + 6 > 10
    }
    
    func test_contactPickerLimitChecker_not_allow_to_invite_returnsFalse() {
        let harness = Harness()
        XCTAssertFalse(harness.sut.contactPickerLimitChecker(callParticipantCount: 100, selectedCount: 100, allowsNonHostToInvite: false))
    }
    
    func test_contactPickerLimitChecker_allow_to_invite_underLimit_returnsFalse() {
        let harness = Harness() // 10 > 5 + 4
        XCTAssertFalse(harness.sut.contactPickerLimitChecker(callParticipantCount: 5, selectedCount: 4, allowsNonHostToInvite: true))
    }
    
    func test_contactPickerLimitChecker_allow_to_invite_overLimit_returnsTrue() {
        let harness = Harness() // 10 < 5 + 6
        XCTAssertTrue(harness.sut.contactPickerLimitChecker(callParticipantCount: 6, selectedCount: 5, allowsNonHostToInvite: true))
    }
    
    func test_callStatusChange_updatesLimit() {
        let harness = Harness()
        XCTAssertEqual(harness.limitsUpdatedCount, 0)
        harness.callStarted(maxUsers: 5)
        evaluate {
            harness.limitsUpdatedCount == 1
        }
    }
}
