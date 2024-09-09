import MEGASwiftUI
import UIKit

extension NodeInfoWrapperViewController: SnackBarPresenting {
    func snackBarContainerView() -> UIView? {
        snackBarContainer
    }

    func layout(snackBarView: UIView?) {
        snackBarContainer?.removeFromSuperview()
        snackBarContainer = snackBarView
        snackBarContainer?.backgroundColor = .clear

        guard let snackBarView else { return }

        snackBarView.translatesAutoresizingMaskIntoConstraints = false
        let bottomOffset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0 ? 32 : 0

        NSLayoutConstraint.activate([
            snackBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snackBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snackBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomOffset)
        ])
    }

    func configureSnackBarPresenter() {
        SnackBarRouter.shared.configurePresenter(self)
    }

    func removeSnackBarPresenter() {
        SnackBarRouter.shared.removePresenter()
    }

    func showSnackBar(with message: String) {
        SnackBarRouter.shared.present(snackBar: SnackBar(message: message))
    }
}
