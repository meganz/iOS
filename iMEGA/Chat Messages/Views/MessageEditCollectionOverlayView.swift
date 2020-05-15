import MessageKit

protocol MessagesEditCollectionOverlayViewDelegate : AnyObject {
    func editOverlayView(_ editOverlayView: MessageEditCollectionOverlayView, activated: Bool)
}

class MessageEditCollectionOverlayView : MessageReusableView {
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
        print("overlayViewTapped")
        isActive = !isActive
        delegate?.editOverlayView(self, activated: isActive)
    }
    
    func configureDisplaying(isActive: Bool) {
        self.isActive = isActive
    }
}
