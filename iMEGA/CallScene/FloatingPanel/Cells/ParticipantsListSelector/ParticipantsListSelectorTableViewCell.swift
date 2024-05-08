import MEGAL10n
import UIKit

class ParticipantsListSelectorTableViewCell: UITableViewCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var segmentedControlChangeHandler: ((ParticipantsListTab) -> Void)?
    private var tabs: [ParticipantsListTab] = []
    
    func configureFor(tabs: [ParticipantsListTab], selectedTab: ParticipantsListTab) {
        self.tabs = tabs
        
        if tabs.count == 2 && segmentedControl.numberOfSegments == 3 {
            segmentedControl.removeSegment(at: 2, animated: false)
        } else if tabs.count == 3 && segmentedControl.numberOfSegments == 2 {
            segmentedControl.insertSegment(withTitle: tabs[2].title, at: 2, animated: false)
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
