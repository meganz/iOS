import UIKit

extension ChatViewController {
    
    func showTopBannerButton() {
        if topBannerButton.isHidden {
            topBannerButton.isHidden = false
            topBannerButtonTopConstraint?.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func hideTopBannerButton() {
        if !topBannerButton.isHidden {
            topBannerButtonTopConstraint?.constant = -44
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            }) { finished in
                if finished {
                    self.topBannerButton.isHidden = true
                }
            }
        }
    }
    
    func checkIfChatHasActiveCall() {
        
    }
    
    func configureTopBannerButtonForInProgressCall() {
        
    }
    
    func configureTopBannerButtonForActiveCall() {
        
    }
}
