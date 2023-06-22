import AVFoundation
import Foundation

struct DevicePermission {

    var requestVideo: (
        _ videoPermissionRequestCompletion: @escaping (Bool) -> Void
    ) -> Void

    var requestAudio: (
        _ audioPermissionRequestCompletion: @escaping (Bool) -> Void
    ) -> Void
}

extension DevicePermission {

    static var live: DevicePermission {
        return Self(
            requestVideo: { completion in
                DispatchQueue.main.async {
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
                }
            },
            requestAudio: { completion in
                DispatchQueue.main.async {
                    AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
                }
            }
        )
    }
}
