import MEGAAppSDKRepo
import MEGADesignToken
import UIKit

class ContactLinkContentView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageViewContainer: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var message: MEGAChatMessage? {
        didSet {
            configureView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            updateAppearance(with: traitCollection)
            registerForAppearanceChanges()
        }
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (view: ContactLinkContentView, _: UITraitCollection) in
            view.updateAppearance(with: view.traitCollection)
        }
    }

    private func updateAppearance(with trait: UITraitCollection) {
        backgroundColor = .mnz_chatRichLinkContentBubble(trait)
        titleLabel.textColor = UIColor.label
        descriptionLabel.textColor = TokenColors.Text.secondary
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        imageView.clipsToBounds = true
    }
    
    func configureView() {
        guard let message else { return }
        titleLabel.text = message.richTitle
        descriptionLabel.text = message.richString
        
        let userHandle = message.contactLinkUserHandle
        if message.contactLinkUserHandle != .invalid && message.contactLinkUserHandle != 0 {
            imageView.mnz_setImage(forUserHandle: userHandle, name: message.richString ?? "")
        }
    }
    
    func showLoading() {
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    func hideLoading() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }
}
