import MEGAL10n
import UIKit

class MeetingInviteParticipantTableViewCell: UITableViewCell {
    @IBOutlet private weak var inviteLabel: UILabel!
    
    var cellTappedHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        inviteLabel.text = Strings.Localizable.Meetings.Panel.inviteParticipants
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:))))
    }
    
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        cellTappedHandler?()
    }
}
