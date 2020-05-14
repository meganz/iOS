
import UIKit

class AddToChatMenuView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageBackgroundView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var menu: AddToChatMenu? {
        didSet {
            guard let menu = menu else {
                imageView.image = nil
                label.text = nil
                imageBackgroundView.isHidden = true
                return
            }
            
            imageView.image = UIImage(named: menu.imageKey)
            label.text = AMLocalizedString(menu.nameKey)
            imageBackgroundView.isHidden = false
        }
    }
    
    func disable(_ disable: Bool) {
        imageView.alpha = disable ? 0.5 : 1.0
        label.alpha = disable ? 0.5 : 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.bounds.width / 2.0
    }

}
