import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import UIKit

class MeetingParticipantTableViewCell: UITableViewCell, ViewType {    

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var moderatorTextLabel: UILabel!
    @IBOutlet private weak var contextMenuButton: UIButton!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        moderatorTextLabel.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface3 :
            .whiteFFFFFF.withAlphaComponent(0.1957759226)
        moderatorTextLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : .white
        moderatorTextLabel.layer.cornerRadius = 4.0
        moderatorTextLabel.layer.masksToBounds = true
        moderatorTextLabel.text = "  \(Strings.Localizable.Meetings.Participant.moderator)  "
        if UIColor.isDesignTokenEnabled() {
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
        } else {
            nameLabel.textColor = .white
            micButton.tintColor = .white
            videoButton.tintColor = .white
            contextMenuButton.tintColor = .white
        }
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
        case .configView(let isModerator, let isMicMuted, let isVideoOn, let shouldHideContextMenu):
            moderatorTextLabel.isHidden = !isModerator
            contextMenuButton.isHidden = shouldHideContextMenu
            micButton.isSelected = isMicMuted
            videoButton.isSelected = !isVideoOn

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
