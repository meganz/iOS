import MEGAAssets
import UIKit

class RecoveryKeyTableViewCell: UITableViewCell {

    @IBOutlet weak var recoveryKeyLabel: UILabel!
    @IBOutlet weak var recoveryKeyContainerView: UIView!
    @IBOutlet weak var backupRecoveryKeyLabel: UILabel!
    @IBOutlet weak var fileTypeTextImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        MainActor.assumeIsolated {
            recoveryKeyContainerView.layer.cornerRadius = 4
            fileTypeTextImageView.image = MEGAAssets.UIImage.image(named: "filetype_text")
        }
    }

}
