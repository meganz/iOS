extension CustomModalAlertViewController: SnackBarPresenting {
    @MainActor
    func layout(snackBarView: UIView?) {
        guard let viewModel else { return }
        viewModel.snackBarContainerView?.removeFromSuperview()
        viewModel.setSnackBarContainerView(snackBarView)
        viewModel.snackBarContainerView?.backgroundColor = .clear

        guard let snackBarView else {
            return
        }

        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        let toolbarHeight = navigationController?.toolbar.frame.height ?? 0
        let bottomOffset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0 ? 32 : 0

        [snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -toolbarHeight - bottomOffset)].activate()
    }

    func snackBarContainerView() -> UIView? {
        viewModel.snackBarContainerView
    }
}
