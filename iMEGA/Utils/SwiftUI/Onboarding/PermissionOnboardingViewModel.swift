import MEGAPermissions
import MEGAPresentation

protocol PermissionOnboardingRequesting: Sendable {
    func requestPermission() async
}

struct PermissionOnboardingRequester: PermissionOnboardingRequesting {
    enum PermissionType {
        case notifications
        case photos
    }
    private let devicePermissionHandler: any DevicePermissionsHandling
    private let permissionType: PermissionType
    
    init(
        permissionType: PermissionType,
        devicePermissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
    ) {
        self.permissionType = permissionType
        self.devicePermissionHandler = devicePermissionHandler
    }

    func requestPermission() async {
        switch permissionType {
        case .notifications:
            _ = await devicePermissionHandler.requestNotificationsPermission()
        case .photos:
            _ = await devicePermissionHandler.requestPhotoLibraryAccessPermissions()
        }
    }
}

final class PermissionOnboardingViewModel: ViewModel<PermissionOnboardingViewModel.Route> {
    enum Route {
        case finished
    }

    let image: ImageResource
    let title: String
    let description: String
    let note: String?

    let primaryButtonTitle: String
    let secondaryButtonTitle: String

    private let permissionRequester: any PermissionOnboardingRequesting

    init(
        image: ImageResource,
        title: String,
        description: String,
        note: String?,
        primaryButtonTitle: String,
        secondaryButtonTitle: String,
        permissionRequester: some PermissionOnboardingRequesting
    ) {
        self.image = image
        self.title = title
        self.description = description
        self.note = note
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.permissionRequester = permissionRequester
    }

    func onPrimaryButtonTap() async {
        await permissionRequester.requestPermission()
        routeTo(.finished)
    }

    func onSecondaryButtonTap() async {
        routeTo(.finished)
    }
}
