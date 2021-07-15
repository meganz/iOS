

@objc class MeetingCompatibilityWarning: NSObject {
    private struct Constants {
        static let timerDuration: TimeInterval = 26.0
        static let maxWidth: CGFloat = 600.0
        static let padding: CGFloat = 16.0
        static let animationDuration: TimeInterval = 0.4
    }
    
    private weak var inView: UIView?
    private let bottomPadding: CGFloat
    private weak var meetingCompatibilityWarningView: MeetingCompatibilityWarningView?
    private var compatibilityWarningViewShowTimer: Timer?
    private let buttonTapHandler: () -> Void
    
    init(inView: UIView, bottomPadding: CGFloat, buttonTapHandler: @escaping () -> Void) {
        self.inView = inView
        self.bottomPadding = bottomPadding
        self.buttonTapHandler = buttonTapHandler
    }
    
    func removeCompatibilityWarningView() {
        guard let meetingCompatibilityWarningView = meetingCompatibilityWarningView else {
            return
        }
        
        meetingCompatibilityWarningView.removeFromSuperview()
        self.meetingCompatibilityWarningView = nil
    }
    
    func startCompatibilityWarningViewTimer() {
        guard compatibilityWarningViewShowTimer == nil else {
            return
        }
        
        compatibilityWarningViewShowTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerDuration, repeats: false) { [weak self] _ in
            self?.showCompatibilityWarningView()
        }
    }
    
    func stopCompatibilityWarningViewTimer() {
        compatibilityWarningViewShowTimer?.invalidate()
        compatibilityWarningViewShowTimer = nil
    }
    
    private func showCompatibilityWarningView() {
        guard meetingCompatibilityWarningView == nil,
              let inView = inView else {
            return
        }
        
        let meetingCompatibilityWarningView = MeetingCompatibilityWarningView.instanceFromNib
        meetingCompatibilityWarningView.buttonTappedHandler = { [weak self] in
            self?.buttonTapHandler()
        }
        meetingCompatibilityWarningView.alpha = 0.0
        inView.addSubview(meetingCompatibilityWarningView)
        inView.bringSubviewToFront(meetingCompatibilityWarningView)
        self.meetingCompatibilityWarningView = meetingCompatibilityWarningView
        
        meetingCompatibilityWarningView.translatesAutoresizingMaskIntoConstraints = false
        
        let widthAnchor = meetingCompatibilityWarningView.widthAnchor.constraint(equalToConstant: Constants.maxWidth)
        widthAnchor.priority = .defaultHigh
        
        [
            widthAnchor,
            meetingCompatibilityWarningView.centerXAnchor.constraint(equalTo: inView.centerXAnchor),
            meetingCompatibilityWarningView.leadingAnchor.constraint(greaterThanOrEqualTo: inView.leadingAnchor, constant: Constants.padding),
            meetingCompatibilityWarningView.trailingAnchor.constraint(lessThanOrEqualTo: inView.trailingAnchor, constant: -Constants.padding),
            meetingCompatibilityWarningView.bottomAnchor.constraint(equalTo: inView.bottomAnchor, constant: -bottomPadding)
        ].activate()
        
        UIView.animate(withDuration: Constants.animationDuration) {
            meetingCompatibilityWarningView.alpha = 1.0
        }
    }
    
    deinit {
        stopCompatibilityWarningViewTimer()
    }
}
