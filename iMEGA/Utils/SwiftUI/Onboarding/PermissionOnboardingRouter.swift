import Combine
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import SwiftUI

@MainActor
final class PermissionOnboardingRouter {
    enum PermissionOnboardingType {
        case notifications
        case cameraBackups
    }

    private let permissionsHandler: any DevicePermissionsHandling

    private var task: Task<Bool, Never>?

    init(permissionsHandler: some DevicePermissionsHandling) {
        self.permissionsHandler = permissionsHandler
    }

    /// Start the Permission Onboarding screen flow
    /// - Parameters:
    ///   - window: The window to show the flow on
    ///   - permissionType:
    /// - Returns:
    ///  - nil: The flow isn't shown or it's shown but user chose to skipp
    ///  - true: The flow is shown and permission is granted
    ///  - false: The flow is shown and permission is not granted
    ///
    func start(
        window: UIWindow,
        permissionType: PermissionOnboardingType
    ) async -> Bool? {
        if let task {
            return await task.value
        }
        switch permissionType {
        case .notifications:
            guard await permissionsHandler.shouldAskForNotificationPermission() else { return nil }
        case .cameraBackups:
            guard permissionsHandler.shouldAskForPhotosPermissions else { return nil }
        }

        let viewModel = buildViewModel(for: permissionType)

        let view = PermissionOnboardingView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        task = Task {
            var result = false
            for await route in viewModel.$route.dropFirst().values {
                task?.cancel()
                task = nil
                if case .finished(let succeeded) = route {
                    result = succeeded
                }
                break
            }
            return result
        }

        window.rootViewController = viewController
        return await task?.value
    }

    private func buildViewModel(for onboardingType: PermissionOnboardingType) -> PermissionOnboardingViewModel {
        return switch onboardingType {
        case .notifications:
            PermissionOnboardingViewModel(
                image: .notificationCta,
                title: Strings.Localizable.Onboarding.Cta.Notifications.title,
                description: Strings.Localizable.Onboarding.Cta.Notifications.explanation,
                note: nil,
                primaryButtonTitle: Strings.Localizable.Onboarding.Cta.Notifications.Buttons.enable,
                secondaryButtonTitle: Strings.Localizable.Onboarding.Cta.Notifications.Buttons.skip,
                permissionRequester: PermissionOnboardingRequester(permissionType: .notifications)
            )
        case .cameraBackups:
            PermissionOnboardingViewModel(
                image: .cameraBackupsCta,
                title: Strings.Localizable.Onboarding.Cta.CameraBackups.title,
                description: Strings.Localizable.Onboarding.Cta.CameraBackups.explanation,
                note: Strings.Localizable.Onboarding.Cta.CameraBackups.note,
                primaryButtonTitle: Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.enable,
                secondaryButtonTitle: Strings.Localizable.Onboarding.Cta.CameraBackups.Buttons.skip,
                permissionRequester: PermissionOnboardingRequester(permissionType: .photos)
            )
        }
    }
}
