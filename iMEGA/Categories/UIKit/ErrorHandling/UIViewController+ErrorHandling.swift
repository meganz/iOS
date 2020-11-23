import Foundation

extension UIViewController {

    func handle(
        _ error: Error,
        retryHandler: (() -> Void)? = nil
    ) {
        if let devicePermissionError = error as? DevicePermissionDeniedError {
            handleDevicePermissionError(devicePermissionError)
            return
        }
        handle(error, from: self, retryHandler: retryHandler)
    }

    private func handleDevicePermissionError(_ error: DevicePermissionDeniedError) {
        switch error {
        case .photos: showPhotoAccessAlert()
        case .video: showVideoAccessAlert()
        case .audio: showAudioAccessAlert(forIncomingCall: false)
        case .audioForIncomingCall: showAudioAccessAlert(forIncomingCall: true)
        }
    }
}
