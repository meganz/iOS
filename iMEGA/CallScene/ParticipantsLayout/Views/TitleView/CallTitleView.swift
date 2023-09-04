import Foundation

class CallTitleView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
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
}
