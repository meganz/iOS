import Accounts
import MEGAAppPresentation

extension MEGALoginRequestDelegate {
    
    @MainActor
    @objc func showLoadingView(permissionsPending: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.showLoadingView(permissionsPending: permissionsPending)
    }
}
