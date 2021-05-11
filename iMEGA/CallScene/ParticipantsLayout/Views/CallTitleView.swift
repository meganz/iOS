
import Foundation

class CallTitleView: UIStackView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet weak var layoutModeBarButton: UIBarButtonItem!
    
    override var intrinsicContentSize: CGSize {
       return UIView.layoutFittingExpandedSize
     }
    
    internal func configure(title: String?, subtitle: String?) {
        if title != nil {
            titleLabel.text = title
        }
        if subtitle != nil {
            subtitleLabel.text = subtitle
        }
    }
    
    internal func switchLayoutMode(_ mode: CallLayoutMode) {
        switch mode {
        case .grid:
            layoutModeBarButton.image = UIImage(named: "speakerView")
        case .speaker:
            layoutModeBarButton.image = UIImage(named: "thumbnailsThin")
        }
    }
    
    internal func toggleLayoutButton() {
        layoutModeBarButton.isEnabled = !layoutModeBarButton.isEnabled
    }
}
