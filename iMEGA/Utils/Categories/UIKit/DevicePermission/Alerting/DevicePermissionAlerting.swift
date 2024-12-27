import Foundation
import MEGAPermissions

@MainActor
protocol DevicePermissionAlerting {

    func showVideoAccessAlert(withCompletion completion: (() -> Void)?)

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool)

    func showPhotoAccessAlert()
}

extension DevicePermissionAlerting {
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler())
    }

    func showVideoAccessAlert(withCompletion completion: (() -> Void)? = nil) {
        permissionRouter.alertVideoPermission()
    }

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool) {
        permissionRouter.alertAudioPermission(incomingCall: incomingCall)
    }

    func showPhotoAccessAlert() {
        permissionRouter.alertPhotosPermission()
    }
}
