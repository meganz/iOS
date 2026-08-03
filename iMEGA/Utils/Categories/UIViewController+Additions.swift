import Foundation
import MEGAAppPresentation

extension UIViewController {
    
    static var isAlreadyPresented: Bool {
        var presentedViewController: UIViewController? = UIApplication.mnz_presentingViewController()
        if presentedViewController is Self {
            return true
        } else {
            while presentedViewController?.presentingViewController != nil {
                presentedViewController = presentedViewController?.presentingViewController
                if presentedViewController is Self {
                    return true
                }
            }
        }
        
        return false
    }
    
    @objc func add(_ child: UIViewController, container: UIView, animate: Bool = true) {
        if animate {
            UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.add(child: child, container: container)
            })
        } else {
            add(child: child, container: container)
        }
    }
    
    private func add(child: UIViewController, container: UIView) {
        addChild(child)
        
        child.view.frame = CGRect(x: 0, y: 0, width: container.frame.width, height: container.frame.height)
        child.view.alpha = 1
        container.addSubview(child.view)
        child.didMove(toParent: self)
        
        addConstraints(child.view, in: container)
    }
    
    private func addConstraints(_ contentView: UIView, in container: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraints([
            NSLayoutConstraint(item: container, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: container, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: container, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: container, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 1.0, constant: 0.0)
        ])
    }
    
    func remove(childViewController: UIViewController?) {
        guard let childViewController = childViewController else { return }
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
    }
    
    /// A Boolean value indicating whether the view is currently loaded into memory and the view has been added to a window.
    @objc func isViewReady() -> Bool {
        isViewLoaded && (view.window != nil)
    }
    
    /// Walks down the modal stack from this controller to the topmost one that can present right now.
    ///
    /// Unlike `UIApplication.mnz_presentingViewController()`, the walk stops before a controller that is off window
    /// or on its way out. Those are the states in which `present(_:animated:)` does nothing but log
    /// `Attempt to present … whose view is not in the window hierarchy`, leaving the caller to believe it succeeded.
    /// - Returns: The controller to present on, or `nil` when nothing in the stack can take a presentation.
    func topPresentableViewController() -> UIViewController? {
        var candidate = self

        while let presented = candidate.presentedViewController, presented.isViewReady(), !presented.isBeingDismissed, !presented.isBeingPresented {
            candidate = presented
        }

        /// The walk stops on a controller still holding a modal only when that modal is off window or on its way
        /// out. UIKit refuses a second presentation until it is gone, so there is nothing presentable right now.
        guard candidate.isViewReady(), candidate.presentedViewController == nil else { return nil }

        return candidate
    }

    func presenterViewController() -> UIViewController? {
        guard var viewController = presentedViewController else {
            return self
        }
        
        while let presentedViewController = viewController.presentedViewController {
            viewController = presentedViewController
        }
        
        if viewController.isKind(of: UIAlertController.self) {
            guard let presentingViewController = viewController.presentingViewController else {
                return viewController
            }
            viewController = presentingViewController
        }
        
        return viewController
    }
    
    func addRightCancelBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    func addRightDismissBarButtonItem(with title: String?) {
        let cancelBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Note to self helpers, used for contacts and send to view controllers
extension UIViewController {
    @objc func isNoteToSelfAvailable() -> Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .noteToSelfChat)
    }
    
    @objc func noteToSelfChatListItem() -> MEGAChatListItem? {
        guard let noteToSelfChat = MEGAChatSdk.shared.chatRooms(by: .noteToSelf)?.chatRoom(at: 0) else { return nil }
        return MEGAChatSdk.shared.chatListItem(forChatId: noteToSelfChat.chatId)
    }
}

extension UIViewController {
    static var doneBarButtonStyle: UIBarButtonItem.Style {
        if #available(iOS 26.0, *) {
            return UIBarButtonItem.Style.plain
        } else {
            return UIBarButtonItem.Style.done
        }
    }
}
