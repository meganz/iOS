
import UIKit

class AddToChatAllowAccessCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowAccessTextLabel.text = AMLocalizedString("To share photos and videos allow MEGA to access your gallery")
    }

}
