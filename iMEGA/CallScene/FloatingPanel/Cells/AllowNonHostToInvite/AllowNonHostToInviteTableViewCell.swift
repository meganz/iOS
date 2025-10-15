import MEGAL10n
import UIKit

class AllowNonHostToInviteTableViewCell: UITableViewCell {
    @IBOutlet private weak var allowNonHostSwitch: UISwitch!
    @IBOutlet private weak var allowNonHostLabel: UILabel!
    
    var switchToggleHandler: ((UISwitch) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            allowNonHostLabel.text = Strings.Localizable.Meetings.AddContacts.AllowNonHost.message
        }
    }
    
    func allowNonHostSwitchEnabled(_ enabled: Bool) {
        allowNonHostSwitch.isOn = enabled
    }
    
    @IBAction func allowNonHostToAddParticipantsValueChanged(_ sender: UISwitch) {
        switchToggleHandler?(allowNonHostSwitch)
    }
}
