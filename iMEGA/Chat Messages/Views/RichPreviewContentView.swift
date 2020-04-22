
import UIKit

class RichPreviewContentView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var imageViewContainer: UIView!
    
    var message : MEGAChatMessage? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        if message?.containsMeta?.type == .richPreview {
            guard let richPreview = message?.containsMeta.richPreview else {
                return
            }
            titleLabel.text = richPreview.title
            if (richPreview.previewDescription as NSString).mnz_isEmpty() {
                descriptionLabel.isHidden = true
            } else {
                descriptionLabel.isHidden = false
                descriptionLabel.text = richPreview.previewDescription
            }
            linkLabel.text = URL(string: richPreview.url)?.host
            if richPreview.image != nil {
                imageView.image = UIImage(data: Data(base64Encoded: richPreview.image, options: .ignoreUnknownCharacters)!)
                imageViewContainer.isHidden = false
            } else {
                imageViewContainer.isHidden = true
            }
            
            if richPreview.icon != nil {
                iconImageView.image = UIImage(data: Data(base64Encoded: richPreview.icon, options: .ignoreUnknownCharacters)!)
                iconImageView.isHidden = false
            } else {
                iconImageView.isHidden = true
            }
            
        } else {
            guard let megaLink = message?.megaLink else {
                return
            }
            switch (megaLink as NSURL).mnz_type() {
            case .fileLink:
                let node = message?.node
                titleLabel.text = node?.name
                descriptionLabel.text = Helper.memoryStyleString(fromByteCount: Int64(truncating: node?.size ?? 0))
                linkLabel.text = "mega.nz"
                iconImageView.image = UIImage(named: "favicon")
                imageView.mnz_setThumbnail(by: node)
                
            case .folderLink:
                titleLabel.text = message?.richTitle
                descriptionLabel.text = String(format: "%@\n%@", message!.richString, Helper.memoryStyleString(fromByteCount: max(message!.richNumber.int64Value, 0)))
                linkLabel.text = "mega.nz"
                iconImageView.image = UIImage(named: "favicon")
                imageView.image = UIImage.mnz_folder()
                
            case .publicChatLink:
                titleLabel.text = message?.richString
                descriptionLabel.text = String(format: "%lld %@", message!.richNumber.int64Value, AMLocalizedString("participants", "Label to describe the section where you can see the participants of a group chat"))
                linkLabel.text = "mega.nz"
                iconImageView.image = UIImage(named: "favicon")
                imageView.image = UIImage(named: "groupChat")
                
            default:
                break
            }
        }
    }
}
