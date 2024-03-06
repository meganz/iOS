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

// Contains model data to show warning header
// currently used in upsell BannerView for waiting room limit [MEET-3421]
struct MeetingInfoHeaderData: Equatable {
    static func == (lhs: MeetingInfoHeaderData, rhs: MeetingInfoHeaderData) -> Bool {
        lhs.copy == rhs.copy
    }
    
    // can have bolds with [A] tags
    var copy: String
    // action when user taps Banner view that will present upgrade modal screen
    var linkTapped: (() -> Void)?
}

struct ParticipantsListView: Equatable {
    let sections: [FloatingPanelTableViewSection]
    let hostControlsRows: [HostControlsSectionRow]
    let inviteSectionRow: [InviteSectionRow]
    let tabs: [ParticipantsListTab]
    let selectedTab: ParticipantsListTab
    let participants: [CallParticipantEntity]
    let existsWaitingRoom: Bool
    let currentUserHandle: HandleEntity?
    let isMyselfModerator: Bool
    // if this is not nil, we show a header on top of table of participants
    let infoHeaderData: MeetingInfoHeaderData?
    
    init(
        sections: [FloatingPanelTableViewSection],
        hostControlsRows: [HostControlsSectionRow],
        inviteSectionRow: [InviteSectionRow],
        tabs: [ParticipantsListTab],
        selectedTab: ParticipantsListTab,
        participants: [CallParticipantEntity],
        existsWaitingRoom: Bool,
        currentUserHandle: HandleEntity? = .invalidHandle,
        isMyselfModerator: Bool = false,
        infoHeaderData: MeetingInfoHeaderData?
    ) {
        self.sections = sections
        self.hostControlsRows = hostControlsRows
        self.inviteSectionRow = inviteSectionRow
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.participants = participants
        self.existsWaitingRoom = existsWaitingRoom
        self.currentUserHandle = currentUserHandle
        self.isMyselfModerator = isMyselfModerator
        self.infoHeaderData = infoHeaderData
    }
}
