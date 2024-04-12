import MEGAL10n

// encode the different ways floating panel renders parts of UI depending on the current user privileges,
// NOTE: At the moment of writing, we are waiting for SDK to expose when user is an .nonDismissibleWithUpgradeLink
enum ParticipantLimitWarningMode {
    // essentially here: cannot add participants from waiting room
    // so warning banner is not shown
    case noWarning
    // the same as host, user can invite from waiting room, so he's presented
    // some information about limits
    case dismissible
    // user is owner of the meeting and will be provided the upgrade flow once tapped
    case nonDismissibleWithUpgradeLink
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
        
        if warningMode == .nonDismissibleWithUpgradeLink && freeTierInCallParticipantLimitReached {
            return organizerHostReachedLimit(
                tab: tab,
                presentUpgradeFlow: presentUpgradeFlow
            )
        }
        
        if  warningMode == .dismissible && !hasDismissedBanner {
            if tab == .inCall && freeTierInCallParticipantLimitReached ||
                tab == .waitingRoom && freeTierInCallParticipantPlusWaitingRoomLimitReached {
                return moderatorReachedLimit(
                    dismissFreeUserLimitBanner: dismissFreeUserLimitBanner
                )
            }
        }
        
        return nil
    }
    
    private func organizerHostReachedLimit(
        tab: ParticipantsListTab,
        presentUpgradeFlow: @escaping ActionHandler
    ) -> MeetingInfoHeaderData? {
        
        switch tab {
        case .inCall:
                .init(
                    copy: Strings.Localizable.Meetings.InCall.Banner.Limit100Participants.organizerHost,
                    linkTapped: presentUpgradeFlow,
                    dismissTapped: nil
                )
        case .waitingRoom:
                .init(
                    copy: Strings.Localizable.Meetings.WaitingRoom.Banner.Limit100Participants.organizerHost,
                    linkTapped: presentUpgradeFlow,
                    dismissTapped: nil
                )
        case .notInCall:
            nil
        }
    }
    
    // host and moderator are synonyms
    private func moderatorReachedLimit(
        dismissFreeUserLimitBanner: @escaping ActionHandler
    ) -> MeetingInfoHeaderData {
        .init(
            copy: Strings.Localizable.Meetings.WaitingRoom.Warning.limit100Participants,
            linkTapped: nil,
            dismissTapped: dismissFreeUserLimitBanner
        )
    }
}
