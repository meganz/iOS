import MEGAAssets
import UIKit

class PreviewersView: UIView {

    @IBOutlet weak var previewersLabel: UILabel!
    @IBOutlet weak var showHidePasswordImageView: UIImageView!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        showHidePasswordImageView.image = MEGAAssets.UIImage.image(named: "showHidePassword_white")
    }
}
