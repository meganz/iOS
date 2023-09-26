import MEGAL10n
import MEGAPresentation
import UIKit

class ParticipantInWaitingRoomTableViewCell: UITableViewCell, ViewType {

    var viewModel: ParticipantInWaitingRoomViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    
    @IBAction func admitButtonTapped(_ sender: UIButton) {
        viewModel?.dispatch(.admitButtonTapped)
    }
    
    @IBAction func denyButtonTapped(_ sender: UIButton) {
        viewModel?.dispatch(.denyButtonTapped)
    }
    
    @MainActor
    func executeCommand(_ command: ParticipantInWaitingRoomViewModel.Command) {
        switch command {
        case .updateAvatarImage(let image):
            avatarImageView.image = image
        case .updateName(let name):
            nameLabel.text = name
        }
    }
}
