import Foundation

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
        asyncOnMain {
            permissionRouter.alertVideoPermission()
        }
    }

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool) {
        asyncOnMain {
            permissionRouter.alertAudioPermission(incomingCall: incomingCall)
        }
    }

    func showPhotoAccessAlert() {
        asyncOnMain {
            permissionRouter.alertPhotosPermission()
        }
    }
}
