import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

class RichPreviewContentView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var imageViewContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    private func updateAppearance () {
        backgroundColor = TokenColors.Background.page
        titleLabel.textColor = TokenColors.Text.primary
        descriptionLabel.textColor = TokenColors.Text.secondary
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    var message: MEGAChatMessage? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        if message?.containsMeta?.type == .richPreview {
            guard let richPreview = message?.containsMeta?.richPreview else {
                return
            }
            titleLabel.text = richPreview.title
            if let description = richPreview.previewDescription, description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                descriptionLabel.isHidden = true
            } else {
                descriptionLabel.isHidden = false
                descriptionLabel.text = richPreview.previewDescription
            }
            if let url = richPreview.url {
                linkLabel.text = URL(string: url)?.host
            }
            if let image = richPreview.image,
               let data = Data(base64Encoded: image, options: .ignoreUnknownCharacters) {
                imageView.image = UIImage(data: data)
                imageViewContainer.isHidden = false
            } else {
                imageViewContainer.isHidden = true
            }
            
            if let icon = richPreview.icon,
               let data = Data(base64Encoded: icon, options: .ignoreUnknownCharacters) {
                iconImageView.image = UIImage(data: data)
                iconImageView.isHidden = false
            } else {
                iconImageView.isHidden = true
            }
            
        } else {
            guard let message = message, let megaLink = message.megaLink else {
                return
            }
            switch (megaLink as NSURL).mnz_type() {
            case .fileLink:
                let node = message.node
                titleLabel.text = node?.name
                descriptionLabel.text = String.memoryStyleString(fromByteCount: Int64(truncating: node?.size ?? 0))
                linkLabel.text = DIContainer.appDomainUseCase.domainName
                iconImageView.image = MEGAAssets.UIImage.favicon
                if let node = node {
                    imageView.mnz_setThumbnail(by: node)
                }
            case .folderLink:
                titleLabel.text = message.richTitle
                descriptionLabel.text = String(format: "%@\n%@", message.richString ?? "", String.memoryStyleString(fromByteCount: max(message.richNumber?.int64Value ?? 0, 0)))
                linkLabel.text = DIContainer.appDomainUseCase.domainName
                iconImageView.image = MEGAAssets.UIImage.favicon
                imageView.image = UIImage.mnz_folder()
                
            case .publicChatLink:
                titleLabel.text = message.richString
                descriptionLabel.text = "\(message.richNumber?.int64Value ?? 0) \(Strings.Localizable.participants)"
                linkLabel.text = DIContainer.appDomainUseCase.domainName
                iconImageView.image = MEGAAssets.UIImage.favicon
                imageView.image = MEGAAssets.UIImage.groupChat
                
            default:
                break
            }
        }
    }
}
