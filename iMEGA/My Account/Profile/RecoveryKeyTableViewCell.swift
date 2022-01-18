
import UIKit

class RecoveryKeyTableViewCell: UITableViewCell {

    @IBOutlet weak var recoveryKeyLabel: UILabel!
    @IBOutlet weak var recoveryKeyContainerView: UIView!
    @IBOutlet weak var backupRecoveryKeyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        recoveryKeyContainerView.layer.cornerRadius = 4
        recoveryKeyContainerView.layer.borderWidth = 0.5
        recoveryKeyContainerView.layer.borderColor = Colors.General.Shadow.blackAlpha10.color.cgColor
        recoveryKeyContainerView.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        recoveryKeyContainerView.layer.shadowColor = Colors.General.Shadow.blackAlpha10.color.cgColor
        recoveryKeyContainerView.layer.shadowOpacity = 0.5
    }

}
