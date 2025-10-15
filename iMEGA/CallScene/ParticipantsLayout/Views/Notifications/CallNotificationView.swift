import Foundation

class CallNotificationView: UIView {
    private enum Constants {
        static let minWidth: CGFloat = 160.0
        static let notificationHeight: CGFloat = 44
        static let defaultMargin: CGFloat = 32
        static let defaultPaddingTop: CGFloat = 16
        static let fixedPaddingTop: CGFloat = 160
    }
    
    @IBOutlet weak var notificationLabel: UILabel!

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.size.width - Constants.defaultMargin
    }
    
    private var topLayoutConstraint: NSLayoutConstraint?
    
    private var topPadding: CGFloat? {
        guard let superview = superview else { return nil }
        return Constants.defaultPaddingTop + superview.safeAreaInsets.top
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        MainActor.assumeIsolated {
            layer.cornerRadius = Constants.notificationHeight / 2.0
            notificationLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let labelWidth = notificationLabel.intrinsicContentSize.width + Constants.defaultMargin
        if labelWidth < Constants.minWidth {
            return CGSize(width: Constants.minWidth, height: Constants.notificationHeight)
        } else if labelWidth > maxWidth {
            return CGSize(width: maxWidth, height: Constants.notificationHeight)
        } else {
            return CGSize(width: labelWidth, height: Constants.notificationHeight)
        }
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        
        if let topLayoutConstraint = topLayoutConstraint,
           let topPadding = topPadding {
            topLayoutConstraint.constant = topPadding
        }
    }
    
    // MARK: - Public methods
    
    /// Show an in call notification centred horizontally, with a fade in animation from top of screen and optional fade out.
    /// Used for temporal notifications as user join/leave notifications.
    func show(message: String, backgroundColor: UIColor, textColor: UIColor, autoFadeOut: Bool, extraPaddingTop: Bool = false, completion: (() -> Void)? = nil) {
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
                                     heightAnchor.constraint(equalToConstant: Constants.notificationHeight),
                                     topAnchor.constraint(equalTo: anchorTop, constant: height)
        ])
        
        fadeIn()
                
        if autoFadeOut {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.fadeOut(completion: completion)
            }
        }
    }
    
    /// Show an in call notification centred horizontally and with a padding from the top taking into account safe are insets.
    /// Used for waiting for others to join and call will end notifications.
    func show(message: String, backgroundColor: UIColor, textColor: UIColor) {
        guard let superview = superview else {
            return
        }

        self.notificationLabel.text = message
        self.backgroundColor = backgroundColor
        self.notificationLabel.textColor = textColor
        
        let topLayoutConstraint = topAnchor.constraint(equalTo: superview.topAnchor, constant: topPadding ?? 0.0)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            topLayoutConstraint,
            heightAnchor.constraint(equalToConstant: Constants.notificationHeight)
        ])
        
        self.topLayoutConstraint = topLayoutConstraint
    }
    
    /// Updates a notification message. For example for call will end countdown timer.
    func updateMessage(string: String) {
        self.notificationLabel.text = string
        invalidateIntrinsicContentSize()
    }
    
    /// Show an in call notification centred horizontally and with a fixed padding from the top.
    /// Used for reconnecting and bad network notifications.
    /// It could have a  blink animation through opacity.
    func showWithFixedPosition(message: String, backgroundColor: UIColor, textColor: UIColor, blinking: Bool = false) {
        translatesAutoresizingMaskIntoConstraints = false
        
        guard let superview = superview else {
            return
        }
        
        self.notificationLabel.text = message
        self.backgroundColor = backgroundColor
        self.notificationLabel.textColor = textColor
        let anchorX: NSLayoutXAxisAnchor = superview.centerXAnchor
        let anchorTop: NSLayoutYAxisAnchor = superview.topAnchor
        NSLayoutConstraint.activate([centerXAnchor.constraint(equalTo: anchorX),
                                     heightAnchor.constraint(equalToConstant: Constants.notificationHeight),
                                     topAnchor.constraint(equalTo: anchorTop, constant: Constants.fixedPaddingTop)
        ])
                
        blinking ? addBlinkingAnimation() : removeOpacityAnimations()
    }
    
    // MARK: - Private methods
    
    private func addBlinkingAnimation() {
        UIView.animate(withDuration: 0.8,
                       delay: 0.5,
                       options: [.curveEaseInOut, .autoreverse, .repeat],
                       animations: { [weak self] in self?.notificationLabel.alpha = 0 },
                       completion: nil)
    }
    
    private func removeOpacityAnimations() {
        self.layer.removeAnimation(forKey: "opacity")
    }
    
    private func fadeIn(withDuration duration: TimeInterval = 0.25) {
        var offsetY: CGFloat = frame.size.height + Constants.defaultPaddingTop
        let offsetX: CGFloat = 0

        if let topSafeAreaInsets = superview?.safeAreaInsets.top {
            offsetY += topSafeAreaInsets
        }
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
        })
    }
    
    private func fadeOut(withDuration duration: TimeInterval = 0.25, completion: (() -> Void)?) {
        let offset: CGFloat = superview?.safeAreaInsets.top ?? 0 + frame.size.height + 16

        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: -offset)
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
            completion?()
        })
    }
}
