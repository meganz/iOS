import MEGADesignToken
import MessageKit

class LoadingMessageReusableView: MessageReusableView {

    @IBOutlet weak var loadingView: UIView!
    @IBOutlet var loadingBubbles: [UIView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    func updateAppearance() {
        loadingView.backgroundColor = TokenColors.Background.page
        loadingBubbles.forEach { (view) in
            view.backgroundColor = TokenColors.Background.surface1
        }
    }
}
