import MessageKit

protocol MessagesEditCollectionOverlayViewDelegate : AnyObject {
    func editOverlayView(_ editOverlayView: MessageEditCollectionOverlayView, activated: Bool)
}

class MessageEditCollectionOverlayView : MessageReusableView {
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftIconView: UIImageView!
    open weak var delegate: MessagesEditCollectionOverlayViewDelegate?
    var isActive = false {
        didSet {
            if isActive {
                leftIconView.image = UIImage(named: "checkBoxSelected")
            } else {
                leftIconView.image = UIImage(named: "checkBoxUnselected")
            }
        }
    }
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()

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
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            guard  let indexPath = indexPath,
                let cell = collectionView.cellForItem(at: indexPath) as? MessageContentCell else {
                return
            }
            let messageContainerView = cell.messageContainerView
            centerConstraint.constant = messageContainerView.frame.minY / 2
            
            
            
        }
        
        
    }
}
