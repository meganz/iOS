import Combine
import MEGASwiftUI
import SwiftUI

protocol SnackBarLayoutCustomizable {
    /// Specify the bottom inset of the snack bar to its super view. If not implemented, default to the bottomAnchor view controller's view safeAreaLayoutGuide.
    var additionalSnackBarBottomInset: CGFloat { get }
}

extension SnackBarLayoutCustomizable where Self: UIViewController {
    /// The view controller presenting the snack bar can call this method to notify that snack bar bottom inset is about to change.
    /// - Parameter animated:Specify if snack bar position update is animated. Default is false.
    func refreshSnackBarBottomInset(animated: Bool = false) {
        updateSnackBarBottomInset(additionalSnackBarBottomInset, animated: animated)
    }
}

extension UIViewController {
    /// Show snack bar with given message. 
    /// Note: There's only one snack bar at a time for a view controller. The current showing snack bar, if any, will be removed before showing the new one
    /// - Parameter message: message to be shown
    func showSnackBar(message: String) {
        showSnackBarView(with: message)
    }
    
    /// Show snack bar with a given SnackBar model. 
    /// Note: There's only one snack bar at a time for a view controller. The current showing snack bar, if any, will be removed before showing the new one
    /// - Parameter snackBar: a SnackBar model to be used for showing snack bar
    func showSnackBar(snackBar: SnackBar) {
        showSnackBarView(snackBar)
    }
    
    /// Dismiss current showing snack bar, if any.
    func dismissSnackBar() {
        dismissCurrentSnackBar()
    }
}

// MARK: - Privates
extension UIViewController {
    
    private var currentSnackBarHosting: SnackBarHostingController? {
        children
            .lazy
            .compactMap {
                guard
                    let controller = $0 as? SnackBarHostingController,
                    !controller.isBeingDismissed else {
                    return nil
                }
                return controller
            }
            .first
    }

    fileprivate func updateSnackBarBottomInset(_ bottomInset: CGFloat, animated: Bool) {
        guard let constraint = currentSnackBarHosting?.bottomConstraint else {
            return
        }

        guard animated else {
            constraint.constant = bottomInset
            return
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            constraint.constant = -bottomInset
            self?.view.layoutIfNeeded()
        }
    }
    
    fileprivate func showSnackBarView(with message: String, action: SnackBar.Action? = nil) {
        showSnackBarView(SnackBar(message: message, action: action))
    }
            
    private func showSnackBarView(_ snackBar: SnackBar) {
        MEGALogInfo("[\(type(of: self))] Show SnackBar message: \(snackBar.message)")
        if let currentSnackBarHosting {
            // Push new snack message to existing view
            currentSnackBarHosting.send(snackBar: snackBar)
        } else {
            // Create and present new snackBar view
            buildSnackBarContainer(with: snackBar)
        }
    }
    
    private func buildSnackBarContainer(with snackBar: SnackBar) {
        let snackBarContainer = SnackBarHostingController(snackBar: snackBar)
        addSnackBarContainer(snackBarContainer)
        animateShowingSnackBarView(snackBarContainer.view)
    }
     
    private func addSnackBarContainer(_ controller: SnackBarHostingController) {
        view.addSubview(controller.view)
        addChild(controller)
        controller.didMove(toParent: self)

        layout(controller: controller)
    }
    
    private func layout(controller: SnackBarHostingController) {
        
        let bottomInset: CGFloat = if let snackBarLayoutCustomizable = self as? (any SnackBarLayoutCustomizable) {
            snackBarLayoutCustomizable.additionalSnackBarBottomInset
        } else {
            0
        }
         
        controller.layoutConstraints(bottomInset: bottomInset, constrained: view)
    }
    
    private func animateShowingSnackBarView(_ snackBarView: UIView) {
        snackBarView.alpha = 0.0
        snackBarView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            snackBarView.alpha = 1.0
        }
    }
    
    private func dismissCurrentSnackBar() {
        currentSnackBarHosting?.hide()
    }
}

// MARK: SwiftUI Container and Hosting Controller
private struct SnackBarHostingView: View {
    
    @StateObject var snackMessageHandler: SnackBarHostingController.SnackMessageHandler
    
    var body: some View {
        SnackBarView(snackBar: $snackMessageHandler.snackBar)
    }
}

private final class SnackBarHostingController: UIHostingController<SnackBarHostingView> {
    
    /// Manage the storing and handling of SnackBar messages for a view
    final class SnackMessageHandler: ObservableObject {
        
        @Published var snackBar: SnackBar?
        
        init(snackBar: SnackBar?) {
            self.snackBar = snackBar
        }
        
        func send(snackBar: SnackBar) {
            self.snackBar = snackBar
        }
        
        func hide() {
            snackBar = nil
        }
    }
    
    private lazy var dismissAnimator = {
        
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { [weak self] in
            self?.view.alpha = 0.0
        }
    
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
        return animator
    }()
    
    private(set) var bottomConstraint: NSLayoutConstraint?
    private var snackMessageHandler: SnackMessageHandler?
    private var subscriptions: Set<AnyCancellable> = []
    
    convenience init(snackBar: SnackBar) {
        let snackMessageHandler = SnackMessageHandler(snackBar: snackBar)
        self.init(rootView: SnackBarHostingView(snackMessageHandler: snackMessageHandler))
        self.snackMessageHandler = snackMessageHandler
        
        autoDismissOnNoSnacks(in: snackMessageHandler)
    }
    
    override var isBeingDismissed: Bool { dismissAnimator.state != .inactive }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
        
    func layoutConstraints(bottomInset: CGFloat, constrained toView: UIView) {
        guard view.window != nil else { return }
        
        view.translatesAutoresizingMaskIntoConstraints = false
    
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: toView.safeAreaLayoutGuide.bottomAnchor, constant: -bottomInset)

        [view.leadingAnchor.constraint(equalTo: snackBarViewLeadingAnchor(toView: toView)),
         view.trailingAnchor.constraint(equalTo: snackBarViewTrailingAnchor(toView: toView)),
         bottomConstraint
        ].activate()
        
        self.bottomConstraint = bottomConstraint
    }
        
    func send(snackBar: SnackBar) {
        snackMessageHandler?.send(snackBar: snackBar)
    }
    
    func hide() {
        snackMessageHandler?.hide()
    }
    
    private func snackBarViewLeadingAnchor(toView: UIView) -> NSLayoutXAxisAnchor {
        /// The leadingAnchor of the snackbar.
        /// In most cases, it is the leadingAnchor of safeAreaLayoutGuide of the view.
        /// In cases where the view is intentionally not constrained to the safe area (e.g., MeetingParticipantsLayoutViewController),
        /// it is the leadingAnchor of the view's window
        if let window = toView.window, window.safeAreaInsets.left > toView.safeAreaInsets.left {
            window.safeAreaLayoutGuide.leadingAnchor
        } else {
            toView.safeAreaLayoutGuide.leadingAnchor
        }
    }
    
    private func snackBarViewTrailingAnchor(toView: UIView) -> NSLayoutXAxisAnchor {
        /// The trailingAnchor of the snackbar.
        /// In most cases, it is the trailingAnchor of safeAreaLayoutGuide of the view.
        /// In cases where the view is intentionally not constrained to the safe area (e.g., MeetingParticipantsLayoutViewController),
        /// it is the trailingAnchor of the view's window
        if let window = toView.window, window.safeAreaInsets.right > toView.safeAreaInsets.right {
            window.safeAreaLayoutGuide.trailingAnchor
        } else {
            toView.safeAreaLayoutGuide.trailingAnchor
        }
    }
    
    private func autoDismissOnNoSnacks(in snackMessageHandler: SnackMessageHandler) {
        snackMessageHandler
            .$snackBar
            .first { $0 == nil } // Lets hide & remove once we have receive a nil snack
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self,
                      !isBeingDismissed else {
                    return
                }
                dismissAnimator.startAnimation()
            })
            .store(in: &subscriptions)
    }
}
