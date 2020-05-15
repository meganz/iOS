import UIKit

protocol MessagesEditCollectionOverlayViewDelegate : AnyObject {
    func editOverlayView(_ editOverlayView: MessageEditCollectionOverlayView, activated: Bool)
}

class MessageEditCollectionOverlayView: UICollectionReusableView {
    open weak var delegate: MessagesEditCollectionOverlayViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MessageEditCollectionOverlayView.onTapOverlayButton))
        isUserInteractionEnabled = true
        addGestureRecognizer(tapRecognizer)
    }
    
    @IBAction func onTapOverlayButton(sender: UITapGestureRecognizer) {
        print("overlayViewTapped")
    }
    
}
