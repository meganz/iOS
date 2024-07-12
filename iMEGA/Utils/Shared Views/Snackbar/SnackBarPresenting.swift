protocol SnackBarPresenting where Self: UIViewController {
    func snackBarContainerView() -> UIView?
    func layout(snackBarView: UIView?)
}

extension SnackBarPresenting {
    @MainActor
    func presentSnackBar(viewController: UIViewController) {
        view.addSubview(viewController.view)
        layout(snackBarView: viewController.view)
        
        showSnackBar()
    }
    
    func dismissSnackBar(immediate: Bool = false) {

        guard let containerView = snackBarContainerView() else {
            return
        }
        
        let completion = { [weak self] in
            self?.layout(snackBarView: nil)
        }
        
        guard !immediate else {
            completion()
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            containerView.alpha = 0.0
        }, completion: { _ in completion() })
    }
    
    @MainActor
    func showSnackBar() {
        guard let containerView = snackBarContainerView() else { return }
        
        containerView.alpha = 0.0
        containerView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            containerView.alpha = 1.0
        }
    }
}
