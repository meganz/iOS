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
    private let presenter: UIViewController
    private let permissionsHandler: any DevicePermissionsHandling

    private var task: Task<Void, Never>?

    init(
        presenter: UIViewController,
        permissionsHandler: some DevicePermissionsHandling
    ) {
        self.presenter = presenter
        self.permissionsHandler = permissionsHandler
    }

    func start(permissionType: PermissionOnboardingType) async {
        guard task == nil else { return }

        switch permissionType {
        case .notifications:
            guard await permissionsHandler.shouldAskForNotificationPermission() else { return }
        case .cameraBackups:
            guard permissionsHandler.shouldAskForPhotosPermissions else { return }
        }

        let viewModel = buildViewModel(for: permissionType)

        let view = PermissionOnboardingView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .overFullScreen

        task = Task {
            for await _ in viewModel.$route.dropFirst().values {
                presenter.dismiss(animated: true)
                task?.cancel()
                task = nil
                break
            }
        }

        presenter.present(viewController, animated: true)

        await task?.value
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
