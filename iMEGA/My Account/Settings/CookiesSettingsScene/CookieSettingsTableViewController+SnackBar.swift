extension CookieSettingsTableViewController: SnackBarPresenting {
    func snackBarContainerView() -> UIView? {
        snackBarContainer
    }
    
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainer?.removeFromSuperview()
        snackBarContainer = snackBarView
        snackBarContainer?.backgroundColor = .clear

        guard let snackBarView, let toolBar = navigationController?.toolbar else { return }

        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        
        [snackBarView.leadingAnchor.constraint(equalTo: toolBar.leadingAnchor, constant: 0),
         snackBarView.trailingAnchor.constraint(equalTo: toolBar.trailingAnchor, constant: 0),
         snackBarView.bottomAnchor.constraint(equalTo: toolBar.topAnchor, constant: 0)
        ].activate()
    }
    
    @objc func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }

    @objc func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }
}
