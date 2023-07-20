
extension FolderLinkViewController: SnackBarPresenting {
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainerView?.removeFromSuperview()
        snackBarContainerView = snackBarView
        snackBarContainerView?.backgroundColor = .clear
        
        guard let snackBarView else {
            return
        }
        
        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomConstant: CGFloat = (AudioPlayerManager.shared.isPlayerAlive() ? -65 : 0)
        
        [snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomConstant)].activate()
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
}
