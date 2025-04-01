import MEGAAppPresentation
import MEGADesignToken
import MEGAL10n
import UIKit

class MeetingParticipantTableViewCell: UITableViewCell, ViewType {    

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var raisedHandImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var moderatorTextLabel: UILabel!
    @IBOutlet private weak var contextMenuButton: UIButton!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        moderatorTextLabel.backgroundColor = TokenColors.Background.surface3
        moderatorTextLabel.textColor = TokenColors.Text.primary
        moderatorTextLabel.layer.cornerRadius = 4.0
        moderatorTextLabel.layer.masksToBounds = true
        moderatorTextLabel.text = "  \(Strings.Localizable.Meetings.Participant.moderator)  "
        nameLabel.textColor = TokenColors.Text.primary
        micButton.setImage(
            .userMicOn.withTintColor(TokenColors.Icon.secondary, renderingMode: .alwaysOriginal),
            for: .normal
        )
        micButton.setImage(
            .userMutedMeetings.withTintColor(TokenColors.Icon.secondary, renderingMode: .alwaysOriginal),
            for: .selected
        )
        videoButton.setImage(
            .callSlots.withTintColor(TokenColors.Icon.secondary, renderingMode: .alwaysOriginal),
            for: .normal
        )
        videoButton.setImage(
            .videoOff.withTintColor(TokenColors.Icon.secondary, renderingMode: .alwaysOriginal),
            for: .selected
        )
        contextMenuButton.tintColor = TokenColors.Icon.primary
    }
    
    var viewModel: MeetingParticipantViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self]  in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    @MainActor
    func executeCommand(_ command: MeetingParticipantViewModel.Command) {
        switch command {
        case .configView(let isModerator, let isMicMuted, let isVideoOn, let shouldHideContextMenu, let raisedHand):
            moderatorTextLabel.isHidden = !isModerator
            contextMenuButton.isHidden = shouldHideContextMenu
            micButton.isSelected = isMicMuted
            videoButton.isSelected = !isVideoOn
            raisedHandImageView.isHidden = !raisedHand
        case .updateAvatarImage(let image):
            avatarImageView.image = image
        case .updateName(let name):
            nameLabel.text = name
        case .updatePrivilege(let isModerator):
            moderatorTextLabel.isHidden = !isModerator
        }
    }
    
    @IBAction func contextMenuTapped(_ sender: UIButton) {
        viewModel?.dispatch(.contextMenuTapped(button: sender))
    }
}
