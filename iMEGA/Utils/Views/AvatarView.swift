
import UIKit

@objc enum AvatarViewMode: Int {
    case single
    case multiple
}

class AvatarView: UIView {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstPeerAvatarImageView: UIImageView!
    @IBOutlet weak var secondPeerAvatarImageView: UIImageView!
    
    private var customView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    func customInit() {
        customView = Bundle.init(for: type(of: self)).loadNibNamed("AvatarView", owner: self, options: nil)?.first as? UIView
        if let view = customView {
            addSubview(view)
            view.frame = bounds
        }
        if #available(iOS 11.0, *) {
            avatarImageView.accessibilityIgnoresInvertColors            = true
            firstPeerAvatarImageView.accessibilityIgnoresInvertColors   = true
            secondPeerAvatarImageView.accessibilityIgnoresInvertColors  = true
        }
    }
    
    @objc func configure(mode: AvatarViewMode) {
        switch mode {
        case .single:
            avatarImageView.isHidden            = false
            firstPeerAvatarImageView.isHidden   = true
            secondPeerAvatarImageView.isHidden  = true
        case .multiple:
            avatarImageView.isHidden            = true
            firstPeerAvatarImageView.isHidden   = false
            secondPeerAvatarImageView.isHidden  = false
        }
    }
}
