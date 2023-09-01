import Foundation

extension MEGAPhotoBrowserViewController: SnackBarPresenting {
    @MainActor
    func layout(snackBarView: UIView?) {
        snackBarContainer?.removeFromSuperview()
        snackBarContainer = snackBarView
        snackBarContainer?.backgroundColor = .clear

        guard let snackBarView else {
            return
        }

        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        let toolbarHeight = toolbar?.frame.height ?? 0
        let bottomOffset: CGFloat = self.view.safeAreaInsets.bottom
        
        [snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(bottomOffset + toolbarHeight))].activate()
    }

    func snackBarContainerView() -> UIView? {
        snackBarContainer
    }

    @objc func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }

    @objc func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }
}
