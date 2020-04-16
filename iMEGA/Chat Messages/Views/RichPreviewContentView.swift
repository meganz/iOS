
import UIKit

class RichPreviewContentView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var node : MEGANode? {
        didSet {
            titleLabel.text = node?.name
            descriptionLabel.text = Helper.memoryStyleString(fromByteCount: Int64(truncating: node?.size ?? 0))
            linkLabel.text = "mega.nz"
            iconImageView.image = UIImage(named: "favicon")
            imageView.mnz_setThumbnail(by: node)
        }
    }

}
