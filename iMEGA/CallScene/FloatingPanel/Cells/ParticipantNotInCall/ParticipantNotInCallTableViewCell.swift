import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit

public enum ParticipantNotInCallState {
    case notInCall
    case calling
    case noResponse
}

class ParticipantNotInCallTableViewCell: UITableViewCell, ViewType {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var participantStateLabel: UILabel!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var participantStatusView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.image = MEGAAssets.UIImage.image(named: "icon-contacts")
        callButton.setTitle(Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Participant.call, for: .normal)
        callButton.setTitleColor(TokenColors.Link.primary, for: .normal)
    }
    
    var viewModel: ParticipantNotInCallViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    private func updateParticipantStateLabel(_ state: ParticipantNotInCallState) {
        switch state {
        case .notInCall:
            callButton.isHidden = false
            participantStateLabel.text = Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Participant.State.notInCall
        case .calling:
            callButton.isHidden = true
            participantStateLabel.text = Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Participant.State.calling
        case .noResponse:
            callButton.isHidden = false
            participantStateLabel.text = Strings.Localizable.Calls.Panel.ParticipantsNotInCall.Participant.State.noResponse
        }
    }
    
    private func updateParticipantChatStatusView(_ status: ChatStatusEntity) {
        participantStatusView.backgroundColor = status.uiColor
    }
    
    @MainActor
    func executeCommand(_ command: ParticipantNotInCallViewModel.Command) {
        switch command {
        case .configView(let state, let status):
            updateParticipantChatStatusView(status)
            updateParticipantStateLabel(state)
        case .updateAvatarImage(let image):
            avatarImageView.image = image
        case .updateName(let name):
            nameLabel.text = name
        case .updatePrivilege(let isModerator):
            participantStateLabel.isHidden = !isModerator
        case .updateStatus(let status):
            updateParticipantChatStatusView(status)
        case .updateState(let state):
            updateParticipantStateLabel(state)
        }
    }
    
    @IBAction func callButtonTapped(_ sender: Any) {
        viewModel?.dispatch(.onCallButtonTapped)
    }
}
