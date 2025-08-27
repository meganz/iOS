@testable import MEGA
import MEGAL10n
import XCTest

final class MeetingFloatingPanelBannerFactoryTests: XCTestCase {
    class Harness {
        let sut = MeetingFloatingPanelBannerFactory()
        
        func result(
            tab: ParticipantsListTab,
            freeTierInCallParticipantLimitReached: Bool = false,
            freeTierInCallParticipantPlusWaitingRoomLimitReached: Bool = false,
            warningMode: ParticipantLimitWarningMode,
            hasDismissedBanner: Bool = false
        ) -> MeetingInfoHeaderData? {
            sut.infoHeaderData(
                tab: tab,
                freeTierInCallParticipantLimitReached: freeTierInCallParticipantLimitReached,
                freeTierInCallParticipantPlusWaitingRoomLimitReached: freeTierInCallParticipantPlusWaitingRoomLimitReached,
                warningMode: warningMode,
                hasDismissedBanner: hasDismissedBanner,
                dismissFreeUserLimitBanner: {}
            )
        }
    }
    
    func testNoBanner_InNotInCallTab_regularParticipant() {
        let harness = Harness()
        let result = harness.result(tab: .notInCall, warningMode: .noWarning)
        XCTAssertNil(result)
    }
    
    func testNoBanner_InNotInCallTab_moderator() {
        let harness = Harness()
        let result = harness.result(tab: .notInCall, warningMode: .dismissible)
        XCTAssertNil(result)
    }
    
    func testNoBanner_ifDidNotReachParticipantLimit_InCallTab_regularParticipant() {
        let harness = Harness()
        let result = harness.result(
            tab: .inCall,
            freeTierInCallParticipantLimitReached: false,
            warningMode: .noWarning
        )
        XCTAssertNil(result)
    }
    
    func testNoBanner_ifDidNotReachParticipantLimit_InCallTab_moderator() {
        let harness = Harness()
        let result = harness.result(
            tab: .inCall,
            freeTierInCallParticipantLimitReached: false,
            warningMode: .dismissible
        )
        XCTAssertNil(result)
    }
    
    func testNoBanner_ifDidNotReachParticipantLimit_WaitingRoomTab_moderator() {
        let harness = Harness()
        let result = harness.result(
            tab: .waitingRoom,
            freeTierInCallParticipantLimitReached: false,
            warningMode: .dismissible
        )
        XCTAssertNil(result)
    }
    
    func testNoBanner_ifDidNotReachParticipantLimit_WaitingRoomTab_regularParticipant() {
        let harness = Harness()
        let result = harness.result(
            tab: .waitingRoom,
            freeTierInCallParticipantLimitReached: false,
            warningMode: .noWarning
        )
        XCTAssertNil(result)
    }
    
    func testBannerTitleAndDismiss_InCall_isModerator_hasReachedLimit() throws {
        let harness = Harness()
        let maybeResult = harness.result(
            tab: .inCall,
            freeTierInCallParticipantLimitReached: true,
            warningMode: .dismissible
        )
        let result = try XCTUnwrap(maybeResult)
        XCTAssertEqual(result.copy, Strings.Localizable.Meetings.Warning.overParticipantLimit)
        XCTAssertNotNil(result.dismissTapped)
    }
    
    func testBannerTitleAndDismiss_waitingRoom_isModerator_hasPassedLimit() throws {
        let harness = Harness()
        let maybeResult = harness.result(
            tab: .waitingRoom,
            freeTierInCallParticipantPlusWaitingRoomLimitReached: true,
            warningMode: .dismissible
        )
        let result = try XCTUnwrap(maybeResult)
        XCTAssertEqual(result.copy, Strings.Localizable.Meetings.Warning.overParticipantLimit)
        XCTAssertNotNil(result.dismissTapped)
    }
    
    func testBannerNil_waitingRoom_isRegularParticipant_didNotDismiss() throws {
        let harness = Harness()
        let maybeResult = harness.result(
            tab: .waitingRoom,
            freeTierInCallParticipantLimitReached: true,
            warningMode: .noWarning,
            hasDismissedBanner: false
        )
        XCTAssertNil(maybeResult)
    }
    
    func testNoBanner_waitingRoom_isNotModerator_didDismiss() throws {
        let harness = Harness()
        let maybeResult = harness.result(
            tab: .waitingRoom,
            freeTierInCallParticipantLimitReached: true,
            warningMode: .dismissible,
            hasDismissedBanner: true
        )
        XCTAssertNil(maybeResult)
    }
}
