import MEGAL10n
import UIKit

class ParticipantsListSelectorTableViewCell: UITableViewCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var segmentedControlChangeHandler: ((ParticipantsListTab) -> Void)?
    private var tabs: [ParticipantsListTab] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: MEGAAppColor.White._FFFFFF.uiColor], for: .selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: MEGAAppColor.White._FFFFFF.uiColor], for: .normal)
    }
     
    func configureFor(tabs: [ParticipantsListTab], selectedTab: ParticipantsListTab) {
        self.tabs = tabs
        
        if tabs.count == 2 {
            segmentedControl.removeSegment(at: 2, animated: false)
        }
        
        for (index, tab) in tabs.enumerated() {
            segmentedControl.setTitle(tab.title, forSegmentAt: index)
            if tab == selectedTab {
                segmentedControl.selectedSegmentIndex = index
            }
        }
    }
    
    @IBAction func segmentedControlChange(_ sender: Any) {
        segmentedControlChangeHandler?(tabs[segmentedControl.selectedSegmentIndex])
    }
}
