
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = notificationHeight / 2.0
        notificationLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
    }
    
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
    
    func show(message: String, backgroundColor: UIColor, textColor: UIColor, autoFadeOut: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        
        guard let superview = superview else {
            return
        }
        
        self.notificationLabel.text = message
        self.backgroundColor = backgroundColor
        self.notificationLabel.textColor = textColor
        let height: CGFloat = frame.size.height * -1
        let anchorX: NSLayoutXAxisAnchor = superview.centerXAnchor
        let anchorTop: NSLayoutYAxisAnchor = superview.topAnchor
        NSLayoutConstraint.activate([centerXAnchor.constraint(equalTo: anchorX),
                                     heightAnchor.constraint(equalToConstant: notificationHeight),
                                     topAnchor.constraint(equalTo: anchorTop, constant: height)
        ])
        
        fadeIn()
        
        if autoFadeOut {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.fadeOut()
            }
        }
    }
    
    func fadeIn(withDuration duration: TimeInterval = 0.5) {
        var offsetY: CGFloat = frame.size.height + 16
        let offsetX: CGFloat = 0

        if let topSafeAreaInsets = superview?.safeAreaInsets.top {
            offsetY += topSafeAreaInsets
        }
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
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
