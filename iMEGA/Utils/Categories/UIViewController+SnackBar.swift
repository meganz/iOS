import MEGASwiftUI
import SwiftUI

/// snackBarViewLookUp is used to store the latest current snack bar view added to the current view controller.
/// There's only one snack bar at a time for a view controller, the returned view can be used to find and remove the current snack bar before adding the new one.
private var snackBarViewLookUp: [String: UIView] = [:]

/// bottomConstraintLookUp is used to store the bottomAnchor constraint of the latest current snack bar view added to the current view controller.
/// The returned constraint can be used to update constant value when needed.
private var bottomConstraintLookUp: [String: NSLayoutConstraint] = [:]

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
        showSnackBarView(with: snackBar)
    }
    
    /// Dismiss current showing snack bar, if any.
    /// - Parameter immediate: Specify if dismiss is animated. Default is true.
    func dismissSnackBar(immediate: Bool = true) {
        guard let currentSnackBarView else { return }
        dismissSnackBarView(currentSnackBarView, immediate: immediate)
    }
}

extension SnackBarViewModel {
    convenience init(snackBar: SnackBar, presenter: UIViewController? = nil) {
        self.init(snackBar: snackBar, willDismiss: {
            if let presenter {
                presenter.dismissSnackBar(immediate: false)
            } else {
                UIApplication.mnz_visibleViewController().dismissSnackBar(immediate: false)
            }
        })
    }
}

protocol SnackBarObservablePresenting where Self: ObservableObject {
    
    @MainActor
    func show(snack: SnackBar)
}

// MARK: - Privates
extension UIViewController {
    private var snackBarViewContainerID: String {
        String(describing: self)
    }
    
    private var currentSnackBarView: UIView? {
        snackBarViewLookUp[snackBarViewContainerID]
    }
    
    fileprivate func updateSnackBarBottomInset(_ bottomInset: CGFloat, animated: Bool) {
        guard let constraint = bottomConstraintLookUp[snackBarViewContainerID] else { return }
        guard animated else {
            constraint.constant = bottomInset
            return
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            constraint.constant = -bottomInset
            self?.view.layoutIfNeeded()
        }
    }
    
    fileprivate func showSnackBarView(with snackBar: SnackBar) {
        let snackBarView = buildSnackBarView(with: snackBar)
        showSnackBarView(snackBarView)
    }
    
    fileprivate func showSnackBarView(with message: String, action: SnackBar.Action? = nil) {
        let snackBarView = buildSnackBarView(message: message, action: action)
        showSnackBarView(snackBarView)
    }
    
    private func buildSnackBarView(with snackBar: SnackBar) -> UIView {
        let willDismiss = { [weak self] in
            guard let snackBarView = self?.currentSnackBarView else { return }
            self?.dismissSnackBarView(snackBarView)
        }
        
        let viewModel = SnackBarViewModel(snackBar: snackBar, willDismiss: willDismiss)
        let view = SnackBarView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        return viewController.view
    }
    
    private func buildSnackBarView(message: String, action: SnackBar.Action? = nil) -> UIView {
        let snackBar = SnackBar(message: message, action: action)
        return buildSnackBarView(with: snackBar)
    }
    
    private func showSnackBarView(_ snackBarView: UIView) {
        // clear previous snack bar before showing the new one
        if let currentSnackBarView {
            dismissSnackBarView(currentSnackBarView, immediate: true)
        }
        addSnackBarView(snackBarView)
        animateShowingSnackBarView(snackBarView)
    }
    
    private func layout(snackBarView: UIView) {
        guard let window = view.window else { return }
        snackBarView.translatesAutoresizingMaskIntoConstraints = false
    
        let bottomInset: CGFloat = if let snackBarLayoutCustomizable = self as? (any SnackBarLayoutCustomizable) {
            snackBarLayoutCustomizable.additionalSnackBarBottomInset
        } else {
            0
        }
         
        let bottomConstraint = snackBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomInset)
        bottomConstraintLookUp[snackBarViewContainerID] = bottomConstraint
        
        // leading and trailing should be contrainted to window safeAreaLayoutGuide
        // the reason is: the view may not be within safe area (as intentionally, e.g MeetingParticipantsLayoutViewController)
        // but we want to make sure the snackbar to be always within safe area.
        [snackBarView.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor),
         bottomConstraint
        ].activate()
    }
    
    private func animateShowingSnackBarView(_ snackBarView: UIView) {
        snackBarView.alpha = 0.0
        snackBarView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            snackBarView.alpha = 1.0
        }
    }
    
    private func animateRemovingSnackBarView(_ snackBarView: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, animations: {
            snackBarView.alpha = 0.0
        }, completion: { _ in
            completion()
        })
    }
    
    private func dismissSnackBarView(_ snackBarView: UIView, immediate: Bool = false) {
        if immediate {
            removeSnackBarView(snackBarView)
            return
        }
        
        animateRemovingSnackBarView(snackBarView) { [weak self] in
            self?.removeSnackBarView(snackBarView)
        }
    }
    
    private func removeSnackBarView(_ snackBarView: UIView) {
        snackBarView.removeFromSuperview()
        snackBarViewLookUp[snackBarViewContainerID] = nil
        bottomConstraintLookUp[snackBarViewContainerID] = nil
    }
    
    private func addSnackBarView(_ snackBarView: UIView) {
        view.addSubview(snackBarView)
        snackBarViewLookUp[snackBarViewContainerID] = snackBarView
        snackBarView.backgroundColor = .clear
        
        layout(snackBarView: snackBarView)
    }
}
