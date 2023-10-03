import MEGAL10n
import UIKit

class SeeAllParticipantsInWaitingRoomTableViewCell: UITableViewCell {
    @IBOutlet private weak var seeAllLabel: UILabel!
    
    var seeAllButtonTappedHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        seeAllLabel?.text = Strings.Localizable.Meetings.Info.Participants.seeAll
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seeAllCellTapped(_:))))
    }
    
    @objc func seeAllCellTapped(_ sender: UITapGestureRecognizer) {
        seeAllButtonTappedHandler?()
    }
}
