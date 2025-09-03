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

    func setRootViewController(shouldShowLoadingScreen: Bool) {
        guard let window = UIApplication.shared.keyWindow else { return }
        Task { @MainActor in
            routeInitialFlow(in: window, shouldShowLoadingScreen: shouldShowLoadingScreen)
        }
    }

    private func routeInitialFlow(in window: UIWindow, shouldShowLoadingScreen: Bool) {
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
                CameraUploadManager.configDefaultSettingsForCameraUploadV2()
                CameraUploadManager.shared().enableCameraUpload()

                let preference = PreferenceWrapper(key: PreferenceKeyEntity.shouldShowCameraUploadsEnabledSnackbar, defaultValue: false, useCase: PreferenceUseCase.default)
                preference.wrappedValue = true
            }
            showMainApp(designatedTab: (photosPermissionGranted == true) ? .cameraUploads : nil)
        }
    }

    private func showMainApp(designatedTab: Tab? = nil) {
        TabManager.setDesignatedTab(tab: designatedTab)

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
