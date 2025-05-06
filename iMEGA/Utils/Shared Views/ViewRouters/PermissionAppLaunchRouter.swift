import Accounts
import MEGAPermissions

@MainActor
protocol PermissionAppLaunchRouterProtocol {
    func setRootViewController()
}

struct PermissionAppLaunchRouter: PermissionAppLaunchRouterProtocol {
    
    func setRootViewController() {
        guard let window = UIApplication.shared.keyWindow else { return }
        
        Task { @MainActor in
            window.rootViewController = await makeLaunchViewController()
        }
    }
    
    private func makeLaunchViewController() async -> UIViewController {
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        if await permissionHandler.shouldSetupPermissions() {
            return AppLoadingViewRouter {
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
            return AppLoadingViewRouter {
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
    }
}
