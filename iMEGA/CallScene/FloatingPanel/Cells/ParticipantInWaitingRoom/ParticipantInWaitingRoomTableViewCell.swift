import MEGAAppPresentation
import MEGAL10n
import UIKit

class ParticipantInWaitingRoomTableViewCell: UITableViewCell, ViewType {

    var viewModel: ParticipantInWaitingRoomViewModel? {
        didSet {
            if let viewModel {
                self.admitButton.isEnabled = viewModel.admitButtonEnabled
                viewModel.invokeCommand = { [weak self] in
                    self?.executeCommand($0)
                }
                viewModel.dispatch(.onViewReady)
            }
        }
    }
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var admitButton: UIButton!
    
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
