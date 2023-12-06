import MEGAL10n
import UIKit

class EmptyParticipantsListTableViewCell: UITableViewCell {
    @IBOutlet weak var emptyParticipantsListLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emptyParticipantsListLabel.text = Strings.Localizable.Calls.Panel.ParticipantsNotInCall.emptyState
    }
}
