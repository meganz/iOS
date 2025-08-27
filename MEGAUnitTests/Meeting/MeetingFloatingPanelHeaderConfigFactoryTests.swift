@testable import MEGA
import MEGAL10n
import XCTest

final class MeetingFloatingPanelHeaderConfigFactoryTests: XCTestCase {
    class Harness {
        let sut: MeetingFloatingPanelHeaderConfigFactory
        let tab: ParticipantsListTab
        init(tab: ParticipantsListTab) {
            self.tab = tab
            sut = MeetingFloatingPanelHeaderConfigFactory(infoBannerFactory: MockMeetingFloatingPanelBannerFactoryProtocol())
        }
        
        class MockMeetingFloatingPanelBannerFactoryProtocol: MeetingFloatingPanelBannerFactoryProtocol {
            func infoHeaderData(
                tab: ParticipantsListTab,
                freeTierInCallParticipantLimitReached: Bool,
                freeTierInCallParticipantPlusWaitingRoomLimitReached: Bool,
                warningMode: ParticipantLimitWarningMode,
                hasDismissedBanner: Bool,
                dismissFreeUserLimitBanner: @escaping ActionHandler
            ) -> MeetingInfoHeaderData? {
                nil
            }
        }
        
        func result(
            freeTierInCallParticipantLimitReached: Bool = false,
            totalInCallAndWaitingRoomAboveFreeTierLimit: Bool = false,
            participantsCount: Int = 0,
            isMyselfAModerator: Bool = false,
            hasDismissedBanner: Bool = false,
            shouldHideCallAllIcon: Bool = false,
            shouldDisableMuteAllButton: Bool = false
        ) -> MeetingParticipantTableViewHeader.ViewConfig {
            sut.headerConfig(
                tab: tab,
                freeTierInCallParticipantLimitReached: freeTierInCallParticipantLimitReached,
                totalInCallAndWaitingRoomAboveFreeTierLimit: totalInCallAndWaitingRoomAboveFreeTierLimit,
                participantsCount: participantsCount,
                isMyselfAModerator: isMyselfAModerator,
                hasDismissedBanner: hasDismissedBanner,
                shouldHideCallAllIcon: shouldHideCallAllIcon,
                shouldDisableMuteAllButton: shouldDisableMuteAllButton,
                dismissFreeUserLimitBanner: {}, 
                actionButtonTappedHandler: {}
            )
        }
    }
    
    func testHeaderTitle_InCallTab() {
        let harness = Harness(tab: .inCall)
        let result = harness.result(participantsCount: 10)
        XCTAssertEqual(result.title, Strings.Localizable.Meetings.Panel.participantsCount(10))
    }
    
    func testHeaderTitle_NotInCallTab() {
        let harness = Harness(tab: .notInCall)
        let result = harness.result(participantsCount: 12)
        XCTAssertEqual(result.title, Strings.Localizable.Meetings.Panel.participantsNotInCallCount(12))
    }
    
    func testHeaderTitle_WaitingRoomTab() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(participantsCount: 7)
        XCTAssertEqual(result.title, Strings.Localizable.Meetings.Panel.participantsInWaitingRoomCount(7))
    }
    
    func testActionButtonTitle_InCallTab() {
        let harness = Harness(tab: .inCall)
        let result = harness.result(participantsCount: 10)
        // only for in call tab, disabled state title is different
        XCTAssertEqual(result.actionButtonDisabledTitle, Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.allMuted)
        XCTAssertEqual(result.actionButtonNormalTitle, Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.muteAll)
    }
    
    func testActionButtonTitle_NotInCallTab() {
        let harness = Harness(tab: .notInCall)
        let result = harness.result(participantsCount: 12)
        XCTAssertEqual(result.actionButtonNormalTitle, result.actionButtonDisabledTitle)
        XCTAssertEqual(result.actionButtonNormalTitle, Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Header.callAll)
    }
    
    func testActionButtonTitle_WaitingRoomTab() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(participantsCount: 7)
        XCTAssertEqual(result.actionButtonNormalTitle, result.actionButtonDisabledTitle)
        XCTAssertEqual(result.actionButtonNormalTitle, Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll)
    }
    
    func testActionButtonHidden_InCallTab() {
        let harness = Harness(tab: .inCall)
        let result_moderator = harness.result(isMyselfAModerator: true)
        XCTAssertEqual(result_moderator.actionButtonHidden, false)
        
        let result_notModerator = harness.result(isMyselfAModerator: false)
        XCTAssertEqual(result_notModerator.actionButtonHidden, true)
    }
    
    func testActionButtonHidden_NotInCallTab() {
        let harness = Harness(tab: .notInCall)
        let result_hideCallAll = harness.result(
            shouldHideCallAllIcon: true
        )
        XCTAssertFalse(result_hideCallAll.actionButtonHidden)
        
        let result_Not_hideCallAll = harness.result(
            shouldHideCallAllIcon: false
        )
        XCTAssertTrue(result_Not_hideCallAll.actionButtonHidden)
        
    }
    
    func test_ActionButton_Hidden_WaitingRoomTab_NoParticipants() {
        let harness = Harness(tab: .waitingRoom)
        let resultNoParticipants = harness.result(participantsCount: 0)
        XCTAssertTrue(resultNoParticipants.actionButtonHidden)
    }
    
    func test_ActionButton_NotHidden_WaitingRoomTab_SomeParticipants() {
        let harness = Harness(tab: .waitingRoom)
        let resultNoParticipants = harness.result(participantsCount: 1)
        XCTAssertFalse(resultNoParticipants.actionButtonHidden)
    }
    
    func testCallAllButtonHidden_InCallTab() {
        let harness = Harness(tab: .inCall)
        let result  = harness.result()
        XCTAssertTrue(result.callAllButtonHidden)
    }
    
    func testCallAllButtonHidden_NotInCallTab() {
        let harness = Harness(tab: .notInCall)
        let result  = harness.result()
        XCTAssertFalse(result.callAllButtonHidden)
    }
    
    func testCallAllButtonHidden_WaitingRoomTab() {
        let harness = Harness(tab: .waitingRoom)
        let result  = harness.result()
        XCTAssertTrue(result.callAllButtonHidden)
    }
    
    func testActionButton_disabledInWaitingRoom_whenHasReachedFreeUserParticipantLimitIsTrue() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(
            
            totalInCallAndWaitingRoomAboveFreeTierLimit: true
            
        )
        XCTAssertFalse(result.actionButtonEnabled)
    }
    
    func testActionButton_enabledInWaitingRoom_whenHasReachedFreeUserParticipantLimitIsFalse_isModerator() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(
            freeTierInCallParticipantLimitReached: false,
            totalInCallAndWaitingRoomAboveFreeTierLimit: false,
            isMyselfAModerator: true
        )
        XCTAssertTrue(result.actionButtonEnabled)
    }
    
    func testWaitingRoomConfig_whenHasReachedFreeUserParticipantLimit_Moderator_totalbelowLimit() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(
            freeTierInCallParticipantLimitReached: false,
            totalInCallAndWaitingRoomAboveFreeTierLimit: true,
            isMyselfAModerator: true
        )
        XCTAssertFalse(result.actionButtonEnabled)
    }
    
    func testWaitingRoomConfig_whenHasReachedFreeUserParticipantLimit_Moderator_totalAboveLimit() {
        let harness = Harness(tab: .waitingRoom)
        let result = harness.result(
            freeTierInCallParticipantLimitReached: true,
            totalInCallAndWaitingRoomAboveFreeTierLimit: true,
            isMyselfAModerator: true
        )
        XCTAssertFalse(result.actionButtonEnabled)
    }
    
    func testActionButton_disabled_when_shouldDisableMuteAllButton_And_InCall() {
        let harness = Harness(tab: .inCall)
        let result = harness.result(
            shouldDisableMuteAllButton: true
        )
        XCTAssertFalse(result.actionButtonEnabled)
    }
    
    func testCallAllButtonHidden_when_shouldHideCallAllIcon_And_NotInCall() {
        let harness = Harness(tab: .notInCall)
        let result = harness.result(
            shouldHideCallAllIcon: true
        )
        XCTAssertTrue(result.callAllButtonHidden)
    }
}
