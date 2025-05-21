import MEGAAssets
import MessageKit

protocol MessagesEditCollectionOverlayViewDelegate: AnyObject {
    func editOverlayView(_ editOverlayView: MessageEditCollectionOverlayView, activated: Bool)
}

class MessageEditCollectionOverlayView: MessageReusableView {
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftIconView: UIImageView!
    open weak var delegate: (any MessagesEditCollectionOverlayViewDelegate)?
    var isActive = false {
        didSet {
            if isActive {
                leftIconView.image = MEGAAssets.UIImage.checkBoxSelected
            } else {
                leftIconView.image = MEGAAssets.UIImage.checkBoxUnselected
            }
        }
    }
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        leftIconView.image = MEGAAssets.UIImage.checkBoxUnselected
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MessageEditCollectionOverlayView.onTapOverlayButton))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapRecognizer)
    }
    
    @objc func onTapOverlayButton(sender: UITapGestureRecognizer) {
        isActive = !isActive
        delegate?.editOverlayView(self, activated: isActive)
    }
    
    func configureDisplaying(isActive: Bool) {
        self.isActive = isActive
    }
}
