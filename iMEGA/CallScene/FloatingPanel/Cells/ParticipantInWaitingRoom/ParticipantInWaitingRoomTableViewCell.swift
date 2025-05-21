import MEGAAppPresentation
import MEGAAssets
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
    @IBOutlet private weak var denyButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureImages()
    }
    
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
    
    private func configureImages() {
        avatarImageView.image = MEGAAssets.UIImage.image(named: "icon-contacts")
        denyButton.setImage(MEGAAssets.UIImage.image(named: "waiting_room_deny"), for: .normal)
        denyButton.setImage(MEGAAssets.UIImage.image(named: "userMutedMeetings"), for: .selected)
        admitButton.setImage(MEGAAssets.UIImage.image(named: "waiting_room_admit"), for: .normal)
        admitButton.setImage(MEGAAssets.UIImage.image(named: "videoOff"), for: .selected)
    }
}
