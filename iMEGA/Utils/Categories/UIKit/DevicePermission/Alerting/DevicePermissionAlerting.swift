import Foundation

protocol DevicePermissionAlerting {

    func showVideoAccessAlert(withCompletion completion: (() -> Void)?)

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool)

    func showPhotoAccessAlert()
}

extension DevicePermissionAlerting {

    func showVideoAccessAlert(withCompletion completion: (() -> Void)? = nil) {
        asyncOnMain {
            DevicePermissionsHelper.alertVideoPermission(completionHandler: completion)
        }
    }

    func showAudioAccessAlert(forIncomingCall incomingCall: Bool) {
        asyncOnMain {
            DevicePermissionsHelper.alertAudioPermission(forIncomingCall: incomingCall)
        }
    }

    func showPhotoAccessAlert() {
        asyncOnMain {
            DevicePermissionsHelper.alertPhotosPermission()
        }
    }
}
