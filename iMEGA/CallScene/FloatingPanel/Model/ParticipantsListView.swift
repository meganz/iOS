import MEGADomain

enum FloatingPanelTableViewSection {
    case hostControls
    case invite
    case participants
}

enum HostControlsSectionRow {
    case listSelector
    case allowNonHostToInvite
}

enum InviteSectionRow {
    case invite
}

typealias ActionHandler = () -> Void

// Contains model data to show warning header
// currently used in upsell BannerView for waiting room limit [MEET-3421]
//    For free-tier-organiser meetings, waiting room and in call tabs show warnings:
// 1. for a host, DISMISSIBLE banner with a warning should be shown on top of the:
//    a) waiting room participant list
//    b) in-call participant list
struct MeetingInfoHeaderData: Equatable {
    static func == (lhs: MeetingInfoHeaderData, rhs: MeetingInfoHeaderData) -> Bool {
        lhs.copy == rhs.copy &&
        (lhs.linkTapped == nil) == (rhs.linkTapped == nil) &&
        (lhs.dismissTapped == nil) == (rhs.dismissTapped == nil)
    }
    
    // can have bolds with [A] tags
    var copy: String
    
    // action when user taps Banner view that will present upgrade modal screen
    // tappable only, if this is not nil
    var linkTapped: ActionHandler?
    
    // show or not show crosshair cancel button
    // rendered only if this is not nil
    var dismissTapped: ActionHandler?
}

// Configuration related to the waiting room tab
struct WaitingRoomConfig: Equatable {
    
    // [MEET-3421]
    // For free-tier organisers, participants in the waiting room cannot be admitted to the meeting
    // unless there are less than 99 + 1 (host) participants/
    // From the user's perspective:
    // 1. in each row, checkmark buttons (admit) in the waiting room tab are disabled
    
    // configures if checkmark button is enabled in each cell
    var allowIndividualWaitlistAdmittance: Bool
}

struct ParticipantsListView: Equatable {
    // if this is not nil, we show a header (MeetingParticipantTableViewHeader) on top of table of participants (waiting room or in call)
    // * banner can be dismissible (once per view controller lifetime) or not
    // * banner can be tappable
    let headerConfig: MeetingParticipantTableViewHeader.ViewConfig
    let sections: [FloatingPanelTableViewSection]
    let hostControlsRows: [HostControlsSectionRow]
    let inviteSectionRow: [InviteSectionRow]
    let tabs: [ParticipantsListTab]
    let selectedTab: ParticipantsListTab
    let participants: [CallParticipantEntity]
    // if this is not nil, waiting room tab is present and configured according to the config
    let waitingRoomConfig: WaitingRoomConfig?
    let currentUserHandle: HandleEntity?
    let isMyselfModerator: Bool
    
    init(
        headerConfig: MeetingParticipantTableViewHeader.ViewConfig,
        sections: [FloatingPanelTableViewSection],
        hostControlsRows: [HostControlsSectionRow],
        inviteSectionRow: [InviteSectionRow],
        tabs: [ParticipantsListTab],
        selectedTab: ParticipantsListTab,
        participants: [CallParticipantEntity],
        waitingRoomConfig: WaitingRoomConfig?,
        currentUserHandle: HandleEntity? = .invalidHandle,
        isMyselfModerator: Bool
    ) {
        self.headerConfig = headerConfig
        self.sections = sections
        self.hostControlsRows = hostControlsRows
        self.inviteSectionRow = inviteSectionRow
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.participants = participants
        self.waitingRoomConfig = waitingRoomConfig
        self.currentUserHandle = currentUserHandle
        self.isMyselfModerator = isMyselfModerator
    }
}
