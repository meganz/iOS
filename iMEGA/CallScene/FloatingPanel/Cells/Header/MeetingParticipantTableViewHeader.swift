import MEGAL10n

final class MeetingParticipantTableViewHeader: UITableViewHeaderFooterView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    
    var actionButtonTappedHandler: (() -> Void)?
    
    func configure(for selectedTab: ParticipantsListTab, participantsCount: Int) {
        switch selectedTab {
        case .inCall:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsCount(participantsCount)
            actionButton.isHidden = true
        case .notInCall:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsNotInCallCount(participantsCount)
            actionButton.isHidden = true
        case .waitingRoom:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsInWaitingRoomCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll, for: .normal)
            actionButton.isHidden = participantsCount > 0 ? false : true
        }
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        actionButtonTappedHandler?()
    }
}
