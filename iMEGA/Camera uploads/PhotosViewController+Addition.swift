import Foundation
import UIKit

extension PhotosViewController {
    @objc func configureStackViewHeight(view: UIView, perviousConstraint: NSLayoutConstraint?) -> NSLayoutConstraint? {
        
        var newConstraint: NSLayoutConstraint?
        let verticalPadding = 24.0
        
        let maxHeight = view.subviews.flatMap({ $0.subviews }).map({ $0.intrinsicContentSize.height }).max() ?? 0
        
        if perviousConstraint == nil {
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight > 0 ? maxHeight + verticalPadding : 0)
        } else {
            perviousConstraint?.isActive = false
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight + verticalPadding)
        }
        newConstraint?.isActive = true
        return newConstraint
    }
}
