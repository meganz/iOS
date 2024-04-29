import SwiftUI
import UIKit

public extension UIView {
    
    @discardableResult 
    func addBlurToView(style: UIBlurEffect.Style) -> UIVisualEffectView {
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)
        return blurEffectView
    }
    
    func removeBlurFromView(view: UIVisualEffectView? = nil) {
        
        guard let view else {
            subviews
                .compactMap { $0 as? UIVisualEffectView }
                .forEach { $0.removeFromSuperview() }
            return
        }
        
        view.removeFromSuperview()
    }
}
