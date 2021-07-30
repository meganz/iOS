
import Foundation

class CallNotificationView: UIView {
    @IBOutlet weak var notificationLabel: UILabel!

    private let minWidth: CGFloat = 160.0
    private var maxWidth: CGFloat {
        get {
            return UIScreen.main.bounds.size.width - defaultMargin
        }
    }
    private let notificationHeight: CGFloat = 44
    private let defaultMargin: CGFloat = 32
    
    override var intrinsicContentSize: CGSize {
        let labelWidth = notificationLabel.intrinsicContentSize.width + defaultMargin
        if labelWidth < minWidth {
            return CGSize(width: minWidth, height: notificationHeight)
        } else if labelWidth > maxWidth {
            return CGSize(width: maxWidth, height: notificationHeight)
        } else {
            return CGSize(width: labelWidth, height: notificationHeight)
        }
    }
    
    func show(message: String, backgroundColor: UIColor, autoFadeOut: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        guard let superview = superview else {
            return
        }
        self.notificationLabel.text = message
        self.backgroundColor = backgroundColor
        NSLayoutConstraint.activate([centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                                     heightAnchor.constraint(equalToConstant: notificationHeight),
                                     topAnchor.constraint(equalTo: superview.topAnchor, constant: -frame.size.height)
        ])
        
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
