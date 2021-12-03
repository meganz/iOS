import UIKit
import FlexLayout
import PinLayout

class RichPreviewDialogView: UIView {
    
    private let rootFlexContainer = UIView()
    private let warmingImageView = UIImageView(image: Asset.Images.Chat.privacyWarningIco.image)
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var alwaysAllowButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.setTitle(NSLocalizedString("never", comment: ""), for: .normal)
        button.isUserInteractionEnabled = true

        return button
    }()
    
    lazy var notNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.isUserInteractionEnabled = true

        return button
    }()
    
    lazy var neverButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.setTitle(NSLocalizedString("never", comment: ""), for: .normal)
        button.isUserInteractionEnabled = true

        return button
    }()
    
    var message : MEGAChatMessage? {
        didSet {
            configureView()
            layout()

        }
    }
    
    init() {
        super.init(frame: .zero)
        updateAppearance()
        rootFlexContainer.flex.define { (flex) in
            flex.addItem().paddingHorizontal(10).define { (flex) in
                flex.addItem().direction(.row).marginTop(10).define { (flex) in
                    flex.addItem(warmingImageView).width(84).height(110)
                    
                    flex.addItem().direction(.column).grow(1).shrink(1).define { (flex) in
                        flex.addItem(titleLabel).grow(1).shrink(1)
                        flex.addItem(descriptionLabel).grow(1).shrink(1)
                    }
                }
                
                flex.addItem(alwaysAllowButton).height(44)
                flex.addItem().height(1).backgroundColor(.systemGray)
                flex.addItem(notNowButton).height(44)
                flex.addItem().height(1).backgroundColor(.systemGray)
                flex.addItem(neverButton).height(44)
                
            }
            
        }
        
        addSubview(rootFlexContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
    
    private func configureView() {
        switch message?.warningDialog {
        case .initial:
            titleLabel.text = NSLocalizedString("enableRichUrlPreviews", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.")
            descriptionLabel.text = NSLocalizedString("richPreviewsFooter", comment: "Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs")
            alwaysAllowButton.setTitle(NSLocalizedString("alwaysAllow", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers."), for: .normal)
            notNowButton.setTitle(NSLocalizedString("notNow", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers."), for: .normal)
            neverButton.flex.display(.none)
        case .standard:
            titleLabel.text = NSLocalizedString("enableRichUrlPreviews", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.")
            descriptionLabel.text = NSLocalizedString("richPreviewsFooter", comment: "Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs")
            alwaysAllowButton.setTitle(NSLocalizedString("alwaysAllow", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers."), for: .normal)
            notNowButton.setTitle(NSLocalizedString("notNow", comment: "Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers."), for: .normal)
            neverButton.setTitle(NSLocalizedString("never", comment: ""), for: .normal)
            neverButton.flex.display(.flex)
        case .confirmation:
            titleLabel.text = NSLocalizedString("richUrlPreviews", comment: "Title used in settings that enables the generation of link previews in the chat")
            descriptionLabel.text = NSLocalizedString("richPreviewsConfirmation", comment: "After several times (right now set to 3) that the user may had decided to click \"Not now\" (for when being asked if he/she wants a URL preview to be generated for a link, posted in a chat room), we change the \"Not now\" button to \"Never\". If the user clicks it, we ask for one final time - to ensure he wants to not be asked for this anymore and tell him that he can do that in Settings.")
            alwaysAllowButton.setTitle(NSLocalizedString("yes", comment: ""), for: .normal)
            notNowButton.setTitle(NSLocalizedString("no", comment: ""), for: .normal)
            neverButton.flex.display(.none)
        default:
            isHidden = true
            break
        }
        
        rootFlexContainer.flex.markDirty()
    }
    
    private func updateAppearance() {
        rootFlexContainer.backgroundColor = .mnz_chatRichLinkContentBubble(traitCollection)
        titleLabel.textColor = .mnz_label()
        descriptionLabel.textColor = .mnz_subtitles(for: traitCollection)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
        
    }
    
    private func layout() {
        // Layout the flexbox container using PinLayout
        // NOTE: Could be also layouted by setting directly rootFlexContainer.frame

        rootFlexContainer.pin.bottom().horizontally()
        
        // Then let the flexbox container layout itself
        rootFlexContainer.flex.layout(mode: .adjustHeight)
        
        pin.bottom().horizontally().height(of: rootFlexContainer)
    }
    
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // 1) Set the contentView's width to the specified size parameter
        rootFlexContainer.pin.width(size.width)
        
        // 2) Layout contentView flex container
        layout()
        
        // Return the flex container new size
        return rootFlexContainer.frame.size
    }
}
