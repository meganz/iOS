import MEGAL10n

// This contains all the logic needed to configure the header in the meeting floating panel table view
// It uses MeetingFloatingPanelBannerFactoryProtocol to extract the logic of banner creation and configuration
// this way they can be independently tested and evaluated if needed, as they are independent from each other

protocol MeetingFloatingPanelHeaderConfigFactoryProtocol {
    func headerConfig(
        tab: ParticipantsListTab,
        freeTierInCallParticipantLimitReached: Bool,
        totalInCallAndWaitingRoomAboveFreeTierLimit: Bool,
        participantsCount: Int,
        isMyselfAModerator: Bool,
        hasDismissedBanner: Bool,
        shouldHideCallAllIcon: Bool,
        shouldDisableMuteAllButton: Bool,
        dismissFreeUserLimitBanner: @escaping ActionHandler,
        actionButtonTappedHandler: @escaping ActionHandler
    ) -> MeetingParticipantTableViewHeader.ViewConfig
}

struct MeetingFloatingPanelHeaderConfigFactory: MeetingFloatingPanelHeaderConfigFactoryProtocol {
    
    var infoBannerFactory: any MeetingFloatingPanelBannerFactoryProtocol
    
    func headerConfig(
        tab: ParticipantsListTab,
        freeTierInCallParticipantLimitReached: Bool, // only in-call
        totalInCallAndWaitingRoomAboveFreeTierLimit: Bool, // in-call + waiting-room
        participantsCount: Int, // this is count for the current 'tab'
        isMyselfAModerator: Bool,
        hasDismissedBanner: Bool,
        shouldHideCallAllIcon: Bool,
        shouldDisableMuteAllButton: Bool,
        dismissFreeUserLimitBanner: @escaping ActionHandler,
        actionButtonTappedHandler: @escaping ActionHandler
    ) -> MeetingParticipantTableViewHeader.ViewConfig {
        .init(
            title: title(
                tab: tab,
                participantsCount: participantsCount
            ),
            actionButtonNormalTitle: actionButtonNormalTitle(tab: tab),
            actionButtonDisabledTitle: actionButtonDisabledTitle(tab: tab),
            actionButtonHidden: actionButtonHidden(
                tab: tab,
                participantsCount: participantsCount,
                isMyselfModerator: isMyselfAModerator,
                shouldHideCallAllIcon: shouldHideCallAllIcon
            ),
            actionButtonEnabled: actionButtonEnabled(
                tab: tab,
                isMyselfAModerator: isMyselfAModerator,
                totalInCallAndWaitingRoomAboveFreeTierLimit: totalInCallAndWaitingRoomAboveFreeTierLimit,
                shouldDisableMuteAllButton: shouldDisableMuteAllButton
            ),
            callAllButtonHidden: callAllButtonHidden(
                tab: tab,
                shouldHideCallAllIcon: shouldHideCallAllIcon
            ),
            actionButtonTappedHandler: actionButtonTappedHandler,
            infoViewModel: infoBannerFactory.infoHeaderData(
                tab: tab,
                freeTierInCallParticipantLimitReached: freeTierInCallParticipantLimitReached, 
                freeTierInCallParticipantPlusWaitingRoomLimitReached: totalInCallAndWaitingRoomAboveFreeTierLimit,
                // [MEET-3663] will also make use of .organizer privilege level
                warningMode: isMyselfAModerator ? .dismissible : .noWarning,
                hasDismissedBanner: hasDismissedBanner,
                dismissFreeUserLimitBanner: dismissFreeUserLimitBanner
            )
        )
    }
    
    private func title(
        tab: ParticipantsListTab,
        participantsCount: Int
    ) -> String {
        switch tab {
        case .inCall:
            Strings.Localizable.Meetings.Panel.participantsCount(participantsCount)
        case .notInCall:
            Strings.Localizable.Meetings.Panel.participantsNotInCallCount(participantsCount)
        case .waitingRoom:
            Strings.Localizable.Meetings.Panel.participantsInWaitingRoomCount(participantsCount)
        }
    }
    
    private func actionButtonNormalTitle(
        tab: ParticipantsListTab
    ) -> String {
        switch tab {
        case .inCall:
            Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.muteAll
        case .notInCall:
            Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Header.callAll
        case .waitingRoom:
            Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll
        }
    }
    
    private func actionButtonDisabledTitle(
        tab: ParticipantsListTab
    ) -> String {
        switch tab {
        case .inCall:
            Strings.Localizable.Calls.Panel.ParticipantsInCall.Header.allMuted
        case .notInCall:
            Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Header.callAll
        case .waitingRoom:
            Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll
        }
    }
    
    private func actionButtonHidden(
        tab: ParticipantsListTab,
        participantsCount: Int,
        isMyselfModerator: Bool,
        shouldHideCallAllIcon: Bool
    ) -> Bool {
        switch tab {
        case .inCall:
            !isMyselfModerator
        case .notInCall:
            // in the notInCall tab we either show action button
            // which is "Call All" OR Call all icon, but not both
            !shouldHideCallAllIcon
        case .waitingRoom:
            participantsCount == 0
        }
    }
    
    private func callAllButtonHidden(
        tab: ParticipantsListTab,
        shouldHideCallAllIcon: Bool
    ) -> Bool {
        switch tab {
        case .inCall:
            true
        case .notInCall:
            shouldHideCallAllIcon
        case .waitingRoom:
            true
        }
    }
    
    private func actionButtonEnabled(
        tab: ParticipantsListTab,
        isMyselfAModerator: Bool,
        totalInCallAndWaitingRoomAboveFreeTierLimit: Bool,
        shouldDisableMuteAllButton: Bool
    ) -> Bool {
        // a host (organiser or non-organiser), cannot admit all (from waiting-room) at once, when
        // organiser is free-tier and total number of in-call and waiting-room users is above limit
        if  tab == .waitingRoom &&
                isMyselfAModerator &&
                totalInCallAndWaitingRoomAboveFreeTierLimit {
            return false
        }
        
        if tab == .waitingRoom && !isMyselfAModerator {
            return false
        }
        
        if tab == .inCall {
            return !shouldDisableMuteAllButton
        }
        
        return true
    }
}
