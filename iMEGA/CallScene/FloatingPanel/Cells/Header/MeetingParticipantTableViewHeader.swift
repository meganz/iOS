import MEGAL10n

final class MeetingParticipantTableViewHeader: UITableViewHeaderFooterView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var callAllIcon: UIImageView!
    
    var actionButtonTappedHandler: (() -> Void)?
    
    func configure(for selectedTab: ParticipantsListTab, participantsCount: Int) {
        switch selectedTab {
        case .inCall:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsCount(participantsCount)
            actionButton.isHidden = true
            callAllIcon.isHidden = true
        case .notInCall:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsNotInCallCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Header.callAll, for: .normal)
            actionButton.isHidden = callAllIcon.isHidden && participantsCount > 0 ? false : true
        case .waitingRoom:
            titleLabel.text = Strings.Localizable.Meetings.Panel.participantsInWaitingRoomCount(participantsCount)
            actionButton.setTitle(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll, for: .normal)
            actionButton.isHidden = participantsCount > 0 ? false : true
            callAllIcon.isHidden = true
        }
    }
    
    func hideCallAllIcon(_ hide: Bool) {
        callAllIcon.isHidden = hide
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        actionButtonTappedHandler?()
    }
}
