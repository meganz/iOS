import MEGAAssets
import MEGAL10n
import UIKit

class EmptyParticipantsListTableViewCell: UITableViewCell {
    @IBOutlet weak var emptyParticipantsListLabel: UILabel!
    @IBOutlet weak var emptyStateImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emptyStateImageView.image = MEGAAssets.UIImage.image(named: "floating panel lists empty state")
    }
    
    func configure(for selectedTab: ParticipantsListTab) {
        switch selectedTab {
        case .inCall:
            break
        case .notInCall:
            emptyParticipantsListLabel.text = Strings.Localizable.Calls.Panel.ParticipantsNotInCall.emptyState
        case .waitingRoom:
            emptyParticipantsListLabel.text = Strings.Localizable.Calls.Panel.ParticipantsInWaitingRoom.emptyState
        }
    }
}
