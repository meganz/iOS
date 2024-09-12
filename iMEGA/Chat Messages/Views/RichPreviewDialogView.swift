import FlexLayout
import MEGADesignToken
import MEGAL10n
import UIKit

class RichPreviewDialogView: UIView {
    
    private let rootFlexContainer = UIView()
    private let warmingImageView = UIImageView(image: UIImage(resource: .privacyWarningIco))
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()
    
    lazy var alwaysAllowButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.setTitle(Strings.Localizable.never, for: .normal)
        button.isUserInteractionEnabled = true
        button.tintColor = TokenColors.Text.primary
        
        return button
    }()
    
    lazy var notNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.isUserInteractionEnabled = true
        button.tintColor = TokenColors.Text.primary
        
        return button
    }()
    
    lazy var neverButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left
        button.setTitle(Strings.Localizable.never, for: .normal)
        button.isUserInteractionEnabled = true
        button.tintColor = TokenColors.Text.primary
        
        return button
    }()
    
    var message: MEGAChatMessage? {
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
            titleLabel.text = Strings.Localizable.enableRichUrlPreviews
            descriptionLabel.text = Strings.Localizable.richPreviewsFooter
            alwaysAllowButton.setTitle(Strings.Localizable.alwaysAllow, for: .normal)
            notNowButton.setTitle(Strings.Localizable.notNow, for: .normal)
            neverButton.flex.display(.none)
        case .standard:
            titleLabel.text = Strings.Localizable.enableRichUrlPreviews
            descriptionLabel.text = Strings.Localizable.richPreviewsFooter
            alwaysAllowButton.setTitle(Strings.Localizable.alwaysAllow, for: .normal)
            notNowButton.setTitle(Strings.Localizable.notNow, for: .normal)
            neverButton.setTitle(Strings.Localizable.never, for: .normal)
            neverButton.flex.display(.flex)
        case .confirmation:
            titleLabel.text = Strings.Localizable.richUrlPreviews
            descriptionLabel.text = Strings.Localizable.richPreviewsConfirmation
            alwaysAllowButton.setTitle(Strings.Localizable.yes, for: .normal)
            notNowButton.setTitle(Strings.Localizable.no, for: .normal)
            neverButton.flex.display(.none)
        default:
            isHidden = true
        }
        
        rootFlexContainer.flex.markDirty()
    }
    
    private func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        titleLabel.textColor = TokenColors.Text.primary
        descriptionLabel.textColor = TokenColors.Text.primary
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
