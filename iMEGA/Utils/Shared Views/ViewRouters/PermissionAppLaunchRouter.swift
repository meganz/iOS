import Accounts
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGAPreference

@MainActor
protocol PermissionAppLaunchRouterProtocol {

    /// Proceed to launch the app after login
    /// - Parameter shouldShowLoadingScreen: Whether to show the Loading screen to fetch node data prior to entering the app
    func setRootViewController(shouldShowLoadingScreen: Bool)
}

struct PermissionAppLaunchRouter: PermissionAppLaunchRouterProtocol {

    private let usesNewFlow: Bool
    init(usesNewFlow: Bool = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)) {
        self.usesNewFlow = usesNewFlow
    }

    func setRootViewController(shouldShowLoadingScreen: Bool) {
        guard let window = UIApplication.shared.keyWindow else { return }
        Task { @MainActor in
            if usesNewFlow {
                handleNewFlow(in: window, shouldShowLoadingScreen: shouldShowLoadingScreen)
            } else {
                window.rootViewController = await makeLaunchViewController()
            }
        }
    }

    func handleNewFlow(in window: UIWindow, shouldShowLoadingScreen: Bool) {
        if shouldShowLoadingScreen {
            window.rootViewController = AppLoadingViewRouter {
                showPermissionsCTAAndGoToApp(in: window)
            }.build()
        } else {
            showPermissionsCTAAndGoToApp(in: window)
        }
    }

    private func showPermissionsCTAAndGoToApp(in window: UIWindow) {
        Task {
            let permissionHandler = DevicePermissionsHandler.makeHandler()
            let router = PermissionOnboardingRouter(permissionsHandler: permissionHandler)
            _ = await router.start(window: window, permissionType: .notifications)
            let photosPermissionGranted = await router.start(window: window, permissionType: .cameraBackups)
            if photosPermissionGranted == true {
                CameraUploadManager.shared().enableCameraUpload()
                let preference = PreferenceWrapper(key: PreferenceKeyEntity.shouldShowCameraUploadsEnabledSnackbar, defaultValue: false, useCase: PreferenceUseCase.default)
                preference.wrappedValue = true
            }
            showMainApp(designatedTabType: (photosPermissionGranted == true) ? .cameraUploads : nil)
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
                showMainApp()
            }
            .build()
        }
    }

    private func showMainApp(designatedTabType: TabType? = nil) {
        if let designatedTabType {
            TabManager.setDesignatedTab(tab: Tab(tabType: designatedTabType))
        }

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
}
