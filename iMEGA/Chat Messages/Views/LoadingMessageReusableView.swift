import MessageKit

class LoadingMessageReusableView: MessageReusableView {

    @IBOutlet weak var loadingView: UIView!
    @IBOutlet var loadingBubbles: [UIView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         super.traitCollectionDidChange(previousTraitCollection)
         
         if #available(iOS 13.0, *),
             traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 updateAppearance()
         }
     }
    
    func updateAppearance() {
        loadingView.backgroundColor = UIColor.mnz_background()
        loadingBubbles.forEach { (view) in
            view.backgroundColor = UIColor.mnz_chatLoadingBubble(traitCollection)
        }
    }
    
}
