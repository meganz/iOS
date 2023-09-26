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
    let selectedTab: ParticipantsListTab
    let participants: [CallParticipantEntity]
    let existsWaitingRoom: Bool
}
