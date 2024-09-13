import UIKit

class RecoveryKeyTableViewCell: UITableViewCell {

    @IBOutlet weak var recoveryKeyLabel: UILabel!
    @IBOutlet weak var recoveryKeyContainerView: UIView!
    @IBOutlet weak var backupRecoveryKeyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        recoveryKeyContainerView.layer.cornerRadius = 4
    }

}
