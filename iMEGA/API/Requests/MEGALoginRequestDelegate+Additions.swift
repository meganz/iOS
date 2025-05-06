import Accounts
import MEGAAppPresentation

extension MEGALoginRequestDelegate {
    @MainActor
    @objc func showLoadingView() {
        PermissionAppLaunchRouter()
            .setRootViewController()
    }
}
