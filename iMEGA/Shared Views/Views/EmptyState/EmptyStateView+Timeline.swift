import UIKit

extension EmptyStateView {
    
    @objc func updateLayoutForTimeline() {
        enableTimelineLayoutConstraint()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            imageWidthConstraint?.constant = 231
        } else {
            if UIDevice.current.orientation.isLandscape {
                imageWidthConstraint?.constant = 100
            } else {
                imageWidthConstraint?.constant = 231
            }
        }
    }
}
