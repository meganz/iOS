import FlexLayout
import MEGAAssets
import MEGADesignToken
import UIKit

class ChatBottomNewMessageIndicatorView: UIView {
    
    private let rootFlexContainer = UIView()
    
    private lazy var badgeLabel: UIButton = {
        let label = UIButton()
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)
        label.configuration = config
        label.backgroundColor = TokenColors.Icon.primary
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.layer.borderWidth = 1
        label.isUserInteractionEnabled = false
        label.layer.borderColor = TokenColors.Text.inverseAccent.cgColor
        return label
    }()
    
    lazy var backgroundView: UIButton = {
        let backgroundView = UIButton()
        backgroundView.layer.cornerRadius = 22
        backgroundView.clipsToBounds = true
        backgroundView.backgroundColor = TokenColors.Icon.primary
        let jumpToLatestImage = MEGAAssets.UIImage.jumpToLatest.withTintColor(TokenColors.Icon.inverseAccent, renderingMode: .alwaysOriginal)
        backgroundView.setImage(jumpToLatestImage, for: .normal)
        
        return backgroundView
    }()
    
    var unreadNewMessagesCount = 0 {
        didSet {
            if unreadNewMessagesCount == 0 {
                badgeLabel.isHidden = true
            } else {
                badgeLabel.isHidden = false
                var attributed = AttributedString((unreadNewMessagesCount > 99) ? "99+" : "\(unreadNewMessagesCount)")
                attributed.font = .systemFont(ofSize: 11, weight: .medium)
                attributed.foregroundColor = TokenColors.Text.inverseAccent
                badgeLabel.configuration?.attributedTitle = attributed
                badgeLabel.flex.markDirty()
                rootFlexContainer.flex.layout()
            }
        }
    }
    
    var tapHandler: (() -> Void)?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        rootFlexContainer.flex.justifyContent(.center).alignItems(.center).size(CGSize(width: 46, height: 46)).define { (flex) in
            flex.addItem(backgroundView).size(CGSize(width: 44, height: 44)).justifyContent(.center).alignItems(.center)
            flex.addItem(badgeLabel).position(.absolute).top(0).right(0).minWidth(20).height(20).grow(1)
        }
        backgroundView.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        addSubview(rootFlexContainer)
    }
    
    // This override is needed as CGColors do not update automatically when appearance changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            badgeLabel.layer.borderColor = TokenColors.Text.inverseAccent.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapped(_ sender: UIButton) {
        tapHandler?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        rootFlexContainer.flex.layout()
    }
}
