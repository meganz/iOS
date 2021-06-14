
import UIKit
import Foundation

class CallNotificationView: UIView {
    @IBOutlet weak var notificationLabel: UILabel!

    private let minWidth: CGFloat = 160.0
    private let maxWidth: CGFloat = UIScreen.main.bounds.size.width - 32
    private let notificationHeight: CGFloat = 44
    private let defaultMargin: CGFloat = 32
    
    override var intrinsicContentSize: CGSize {
        let labelWidth = notificationLabel.intrinsicContentSize.width
        if labelWidth + defaultMargin < minWidth {
            return CGSize(width: minWidth, height: notificationHeight)
        } else if notificationLabel.intrinsicContentSize.width + defaultMargin > maxWidth {
            return CGSize(width: maxWidth, height: notificationHeight)
        } else {
            return CGSize(width: labelWidth + defaultMargin, height: notificationHeight)
        }
    }
    
    func show(message: String, backgroundColor: UIColor, autoFadeOut: Bool) {
        self.notificationLabel.text = message
        self.backgroundColor = backgroundColor
        self.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: -(frame.size.height / 2))
        invalidateIntrinsicContentSize()
        
        fadeIn()
        
        if autoFadeOut {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.fadeOut()
            }
        }
    }
    
    func fadeIn(withDuration duration: TimeInterval = 0.5) {
        var offset: CGFloat = frame.size.height + 16

        if let topSafeAreaInsets = superview?.safeAreaInsets.top {
            offset += topSafeAreaInsets
        }
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: offset)
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 0.3) {
        let offset: CGFloat = superview?.safeAreaInsets.top ?? 0 + frame.size.height + 16

        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: -offset)
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }
}
