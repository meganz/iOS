import Foundation

protocol DevicePermissionAlerting {

    func showVideoAccessAlert(withCompletion completion: (() -> Void)?)

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool)

    func showPhotoAccessAlert()
}

extension DevicePermissionAlerting {

    func showVideoAccessAlert(withCompletion completion: (() -> Void)? = nil) {
        asyncOnMain {
            DevicePermissionsHandler().alertVideoPermissionWith(handler: completion ?? {})
        }
    }

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool) {
        asyncOnMain {
            DevicePermissionsHandler().alertAudioPermission(incomingCall: incomingCall)
        }
    }

    func showPhotoAccessAlert() {
        asyncOnMain {
            DevicePermissionsHandler().alertPhotosPermission()
        }
    }
}
