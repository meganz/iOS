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
        moderatorTextLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1957759226)
        moderatorTextLabel.layer.cornerRadius = 4.0
        moderatorTextLabel.text = "  \(NSLocalizedString("meetings.participant.moderator", comment: ""))  "
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
