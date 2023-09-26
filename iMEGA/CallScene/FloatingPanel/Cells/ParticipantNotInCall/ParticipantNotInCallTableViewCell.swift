import MEGAL10n
import MEGAPresentation
import UIKit

class ParticipantNotInCallTableViewCell: UITableViewCell, ViewType {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var moderatorTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        moderatorTextLabel.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1957759226)
        moderatorTextLabel.layer.cornerRadius = 4.0
        moderatorTextLabel.text = "  \(Strings.Localizable.Meetings.Participant.moderator)  "
    }
    
    var viewModel: MeetingParticipantViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    @MainActor
    func executeCommand(_ command: MeetingParticipantViewModel.Command) {
        switch command {
        case .configView(let isModerator, _, _, _):
            moderatorTextLabel.isHidden = !isModerator
        case .updateAvatarImage(let image):
            avatarImageView.image = image
        case .updateName(let name):
            nameLabel.text = name
        case .updatePrivilege(let isModerator):
            moderatorTextLabel.isHidden = !isModerator
        }
    }
}
