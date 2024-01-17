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
    
    init(
        sections: [FloatingPanelTableViewSection],
        hostControlsRows: [HostControlsSectionRow],
        inviteSectionRow: [InviteSectionRow],
        tabs: [ParticipantsListTab],
        selectedTab: ParticipantsListTab,
        participants: [CallParticipantEntity],
        existsWaitingRoom: Bool,
        currentUserHandle: HandleEntity? = .invalidHandle,
        isMyselfModerator: Bool = false
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
    }
}
