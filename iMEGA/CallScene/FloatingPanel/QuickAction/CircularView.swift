
import UIKit

final class CircularView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }
}
