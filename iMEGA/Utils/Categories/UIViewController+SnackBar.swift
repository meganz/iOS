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
        showSnackBarView(with: snackBar)
    }
    
    /// Dismiss current showing snack bar, if any.
    /// - Parameter immediate: Specify if dismiss is animated. Default is true.
    func dismissSnackBar(immediate: Bool = true) {
        guard let currentSnackBarView else { return }
        dismissSnackBarView(currentSnackBarView, immediate: immediate)
    }
}

// MARK: - Privates
extension UIViewController {
    private struct Constants {
        static let snackBarConstraintIdentifier = "nz.mega.UIViewController.SnackBar.bottomConstraintKey"
        static let snackBarViewTag = 10001
    }

    private var currentSnackBarView: UIView? {
        view.viewWithTag(Constants.snackBarViewTag)
    }

    fileprivate func updateSnackBarBottomInset(_ bottomInset: CGFloat, animated: Bool) {
        guard let constraint = currentSnackBarView?.superview?.constraints.first(
            where: { $0.identifier == Constants.snackBarConstraintIdentifier }
        ) else {
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
    
    fileprivate func showSnackBarView(with snackBar: SnackBar) {
        let snackBarView = buildSnackBarView(with: snackBar)
        showSnackBarView(snackBarView)
    }
    
    fileprivate func showSnackBarView(with message: String, action: SnackBar.Action? = nil) {
        let snackBarView = buildSnackBarView(message: message, action: action)
        showSnackBarView(snackBarView)
    }
    
    private func buildSnackBarView(with snackBar: SnackBar) -> UIView {
        let removeSnackBar = { [weak self] in
            guard let snackBarView = self?.currentSnackBarView else { return }
            self?.dismissSnackBarView(snackBarView)
        }
        
        let snackBarBinding: Binding<SnackBar?> = Binding(
            get: { snackBar },
            set: { newValue in
                if newValue == nil {
                    removeSnackBar()
                }
            })
            
        return UIHostingController(
            rootView: SnackBarView(
                snackBar: snackBarBinding
            )
        ).view
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
        bottomConstraint.identifier = Constants.snackBarConstraintIdentifier

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
            snackBarView.removeFromSuperview()
            return
        }
        
        animateRemovingSnackBarView(snackBarView) {
            snackBarView.removeFromSuperview()
        }
    }
    
    private func addSnackBarView(_ snackBarView: UIView) {
        view.addSubview(snackBarView)
        snackBarView.backgroundColor = .clear
        snackBarView.tag = Constants.snackBarViewTag

        layout(snackBarView: snackBarView)
    }
}
