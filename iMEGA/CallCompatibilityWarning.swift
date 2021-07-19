

@objc class CallCompatibilityWarning: NSObject {
    private struct Constants {
        static let timerDuration: TimeInterval = 26.0
        static let maxWidth: CGFloat = 600.0
        static let padding: CGFloat = 16.0
        static let animationDuration: TimeInterval = 0.4
    }
    
    private weak var inView: UIView?
    private weak var bottomView: UIView?
    private let isOneToOneCall: Bool
    private let buttonTapHandler: () -> Void
    private weak var callCompatibilityWarningView: CallCompatibilityWarningView?
    private var compatibilityWarningViewShowTimer: Timer?
    
    
    @objc init(inView: UIView, placeAboveView bottomView: UIView, isOneToOneCall: Bool, buttonTapHandler: @escaping () -> Void) {
        self.inView = inView
        self.bottomView = bottomView
        self.isOneToOneCall = isOneToOneCall
        self.buttonTapHandler = buttonTapHandler
    }
    
    @objc func removeCompatibilityWarningView() {
        guard let callCompatibilityWarningView = callCompatibilityWarningView else {
            return
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            callCompatibilityWarningView.alpha = 0.0
        } completion: { _ in
            callCompatibilityWarningView.removeFromSuperview()
            callCompatibilityWarningView.alpha = 1.0
            self.callCompatibilityWarningView = nil
        }
    }
    
    @objc func startCompatibilityWarningViewTimer() {
        self.compatibilityWarningViewShowTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerDuration, repeats: false) { [weak self] _ in
            self?.showCompatibilityWarningView()
        }
    }
    
    @objc func stopCompatibilityWarningViewTimer() {
        self.compatibilityWarningViewShowTimer?.invalidate()
        self.compatibilityWarningViewShowTimer = nil
    }
    
    private func showCompatibilityWarningView() {
        guard callCompatibilityWarningView == nil,
              let inView = inView,
              let bottomView = bottomView else {
            return
        }
        
        let callCompatibilityWarningView = CallCompatibilityWarningView.instanceFromNib
        if isOneToOneCall {
            callCompatibilityWarningView.hideButton()
        }
        callCompatibilityWarningView.buttonTapHandler = buttonTapHandler
        callCompatibilityWarningView.alpha = 0.0
        inView.addSubview(callCompatibilityWarningView)
        self.callCompatibilityWarningView = callCompatibilityWarningView
        
        callCompatibilityWarningView.translatesAutoresizingMaskIntoConstraints = false
        
        let widthAnchor = callCompatibilityWarningView.widthAnchor.constraint(equalToConstant: Constants.maxWidth)
        widthAnchor.priority = .defaultHigh
        
        [
            widthAnchor,
            callCompatibilityWarningView.centerXAnchor.constraint(equalTo: inView.centerXAnchor),
            callCompatibilityWarningView.leadingAnchor.constraint(greaterThanOrEqualTo: inView.leadingAnchor, constant: Constants.padding),
            callCompatibilityWarningView.trailingAnchor.constraint(lessThanOrEqualTo: inView.trailingAnchor, constant: -Constants.padding),
            callCompatibilityWarningView.bottomAnchor.constraint(equalTo: bottomView.topAnchor, constant: -Constants.padding)
        ].activate()
        
        UIView.animate(withDuration: Constants.animationDuration) {
            callCompatibilityWarningView.alpha = 1.0
        }
    }
    
    deinit {
        stopCompatibilityWarningViewTimer()
    }
}
