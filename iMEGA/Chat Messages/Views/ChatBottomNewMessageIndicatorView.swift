import UIKit
import FlexLayout

class ChatBottomNewMessageIndicatorView: UIView {
    
    private let rootFlexContainer = UIView()
    
    private lazy var badgeLabel: UIButton = {
        let label = UIButton()
        label.setTitle("", for: .normal)
        label.contentEdgeInsets =  UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
        label.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2039215686, alpha: 0.9)
        label.layer.cornerRadius = 10
        label.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        label.clipsToBounds = true
        label.layer.borderWidth = 1
        label.isUserInteractionEnabled = false
        label.layer.borderColor = UIColor.white.cgColor
        return label
    }()
    
    lazy var backgroundView: UIButton = {
        let backgroundView = UIButton()
        backgroundView.backgroundColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2039215686, alpha: 0.9)
        backgroundView.layer.cornerRadius = 22
        backgroundView.clipsToBounds = true
        backgroundView.setImage(Asset.Images.Chat.jumpToLatest.image, for: .normal)
        return backgroundView
    }()
    
    var unreadNewMessagesCount = 0 {
        didSet {
            if unreadNewMessagesCount == 0 {
                badgeLabel.isHidden = true
            } else {
                badgeLabel.isHidden = false
                badgeLabel.setTitle(unreadNewMessagesCount > 99 ? "99+" : "\(unreadNewMessagesCount)", for: .normal)
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
