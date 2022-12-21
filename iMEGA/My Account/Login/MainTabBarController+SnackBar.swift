
extension MainTabBarController: SnackBarPresenting {
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainerView?.removeFromSuperview()
        snackBarContainerView = snackBarView
        snackBarContainerView?.backgroundColor = .clear
        
        guard let snackBarView else {
            return
        }
        
        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        
        snackBarViewBottomConstraint = snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBar.frame.size.height - (AudioPlayerManager.shared.isPlayerAlive() ? 65 : 0))
        snackBarViewBottomConstraint?.isActive = true
        
        [snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor)].activate()
    }
    
    func snackBarContainerView() -> UIView? {
        snackBarContainerView
    }
    
    @objc func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }
    
    @objc func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }
    
    @objc func refreshSnackBarViewBottomConstraint() {
        guard snackBarContainerView != nil else { return }
        
        snackBarViewBottomConstraint?.constant = -tabBar.frame.size.height - (AudioPlayerManager.shared.isPlayerAlive() ? 65 : 0)
        snackBarContainerView?.layoutIfNeeded()
    }
}
