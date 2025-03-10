import Accounts
import MEGAPresentation

extension MEGALoginRequestDelegate {
    @objc class func isNewLoadingEnabled() -> Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newLoadingView)
    }
    
    @MainActor
    @objc class func showLoadingView(permissionsPending: Bool) {
        var viewController: UIViewController?
        if permissionsPending {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "InitialLaunchViewControllerID"
                ) as? InitialLaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                guard let window = UIApplication.shared.keyWindow else {
                    return
                }
                launchViewController.showViews = true
                window.rootViewController = launchViewController
            }.build()
        } else {
            viewController = AppLoadingViewRouter {
                guard let launchViewController = UIStoryboard(
                    name: "Launch",
                    bundle: nil
                ).instantiateViewController(
                    withIdentifier: "LaunchViewControllerID"
                ) as? LaunchViewController else {
                    return
                }
                launchViewController.delegate = UIApplication.shared.delegate as? any LaunchViewControllerDelegate
                launchViewController.delegate.setupFinished()
                launchViewController.delegate.readyToShowRecommendations()
            }
            .build()
        }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        window.rootViewController = viewController
    }
}
