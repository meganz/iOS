import MEGAL10n
import UIKit

class ParticipantsListSelectorTableViewCell: UITableViewCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var segmentedControlChangeHandler: ((ParticipantsListTab) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        segmentedControl.setTitle(Strings.Localizable.Meetings.Panel.ListSelector.inCall, forSegmentAt: 0)
        segmentedControl.setTitle(Strings.Localizable.Meetings.Panel.ListSelector.notInCall, forSegmentAt: 1)
        segmentedControl.setTitle(Strings.Localizable.Meetings.Panel.ListSelector.inWaitingRoom, forSegmentAt: 2)
    }
    
    @IBAction func segmentedControlChange(_ sender: Any) {
        segmentedControlChangeHandler?(ParticipantsListTab(rawValue: segmentedControl.selectedSegmentIndex) ?? .inCall)
    }
}
