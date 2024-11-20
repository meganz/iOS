import MEGAL10n

// encode the different ways floating panel renders parts of UI depending on the current user privileges,
enum ParticipantLimitWarningMode {
    // essentially here: cannot add participants from waiting room
    // so warning banner is not shown
    case noWarning
    // the same as host, user can invite from waiting room, so he's presented
    // some information about limits
    case dismissible
}

protocol MeetingFloatingPanelBannerFactoryProtocol {
    func infoHeaderData(
        tab: ParticipantsListTab,
        freeTierInCallParticipantLimitReached: Bool,
        freeTierInCallParticipantPlusWaitingRoomLimitReached: Bool,
        warningMode: ParticipantLimitWarningMode,
        hasDismissedBanner: Bool,
        presentUpgradeFlow: @escaping ActionHandler,
        dismissFreeUserLimitBanner: @escaping ActionHandler
    ) -> MeetingInfoHeaderData?
}

// Implement logic of presence and configuration
// of the upsell banner shown in the meeting floating panel
// currently used to inform user about participant number limits for
// free users. For certain configuration this shows dismiss button or
// reacts to link taps.
struct MeetingFloatingPanelBannerFactory: MeetingFloatingPanelBannerFactoryProtocol {
    func infoHeaderData(
        tab: ParticipantsListTab,
        freeTierInCallParticipantLimitReached: Bool,
        freeTierInCallParticipantPlusWaitingRoomLimitReached: Bool,
        warningMode: ParticipantLimitWarningMode,
        hasDismissedBanner: Bool,
        presentUpgradeFlow: @escaping ActionHandler,
        dismissFreeUserLimitBanner: @escaping ActionHandler
    ) -> MeetingInfoHeaderData? {
        
        if warningMode == .dismissible && !hasDismissedBanner {
            if tab == .inCall && freeTierInCallParticipantLimitReached ||
                tab == .waitingRoom && freeTierInCallParticipantPlusWaitingRoomLimitReached {
                return moderatorReachedLimit(
                    dismissFreeUserLimitBanner: dismissFreeUserLimitBanner
                )
            }
        }
        
        return nil
    }
    
    // host and moderator are synonyms
    private func moderatorReachedLimit(
        dismissFreeUserLimitBanner: @escaping ActionHandler
    ) -> MeetingInfoHeaderData {
        .init(
            copy: Strings.Localizable.Meetings.FloatingPanel.Banner.Limit100Participants.nonOrganizerHost,
            linkTapped: nil,
            dismissTapped: dismissFreeUserLimitBanner
        )
    }
}
