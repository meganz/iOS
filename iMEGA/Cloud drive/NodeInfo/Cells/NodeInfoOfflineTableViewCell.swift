import UIKit

class NodeInfoOfflineTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var offlineSwitch: UISwitch!
    
    func configure(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        titleLabel.text = AMLocalizedString("Available Offline", "Text indicating if a node is downloaded locally")
        offlineSwitch.isOn = MEGAStore.shareInstance()?.offlineNode(with: node) != nil
    }
}
