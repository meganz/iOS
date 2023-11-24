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
         
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
     }
    
    func updateAppearance() {
        loadingView.backgroundColor = UIColor.systemBackground
        loadingBubbles.forEach { (view) in
            view.backgroundColor = UIColor.mnz_chatLoadingBubble(traitCollection)
        }
    }
    
}
