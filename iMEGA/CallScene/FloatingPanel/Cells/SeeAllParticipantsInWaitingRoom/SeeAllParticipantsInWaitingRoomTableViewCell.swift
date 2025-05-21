import MEGAAssets
import MEGAL10n
import UIKit

class SeeAllParticipantsInWaitingRoomTableViewCell: UITableViewCell {
    @IBOutlet private weak var seeAllLabel: UILabel!
    @IBOutlet weak var disclosureImageView: UIImageView!
    
    var seeAllButtonTappedHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        disclosureImageView.image = MEGAAssets.UIImage.image(named: "seeMoreWaitingRoomDisclosure")
        seeAllLabel?.text = Strings.Localizable.Meetings.Info.Participants.seeAll
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seeAllCellTapped(_:))))
    }
    
    @objc func seeAllCellTapped(_ sender: UITapGestureRecognizer) {
        seeAllButtonTappedHandler?()
    }
}
