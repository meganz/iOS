import MEGADomain

public class CameraUploadNotifier: NSObject {
    @objc public static func postVideoUploadSettingChanged() {
        NotificationCenter.default.post(
            name: .cameraUploadVideoUploadSettingChanged,
            object: nil
        )
    }
}
