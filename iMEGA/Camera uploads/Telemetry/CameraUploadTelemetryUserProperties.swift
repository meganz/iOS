import Foundation

/// Sets the Camera Upload user properties whose value changed. The values last set are kept across launches, as
/// Firebase keeps the properties. Used only on the telemetry queue.
final class CameraUploadTelemetryUserProperties {
    private static let lastValuesKey = "CameraUploadTelemetryUserProperties"

    private let sink: any CameraUploadTelemetrySink
    private lazy var lastValues = UserDefaults.standard.dictionary(forKey: Self.lastValuesKey) as? [String: String] ?? [:]

    init(sink: any CameraUploadTelemetrySink) {
        self.sink = sink
    }

    func refresh() {
        let changed = currentValues.filter { lastValues[$0.key] != $0.value }
        guard !changed.isEmpty else { return }
        for (name, value) in changed.sorted(by: { $0.key < $1.key }) {
            sink.setUserProperty(value, forName: name)
            lastValues[name] = value
        }
        UserDefaults.standard.set(lastValues, forKey: Self.lastValuesKey)
    }

    /// Forgets the values last set and sets them all again, so a cleared local file starts with them.
    func setAll() {
        lastValues = [:]
        refresh()
    }

    private var currentValues: [String: String] {
        let isEnabled = CameraUploadManager.isCameraUploadEnabled
        let isVideoEnabled = isEnabled && CameraUploadManager.isVideoUploadEnabled
        let mobileData = if !CameraUploadManager.isCellularUploadAllowed {
            "off"
        } else if isVideoEnabled && CameraUploadManager.isCellularUploadForVideosAllowed {
            "all"
        } else {
            "photos"
        }
        let givenUpFiles = CameraUploadRecordManager.shared().givenUpRecordsCount(error: nil)
        return [
            "cu_enabled": isEnabled ? "1" : "0",
            "cu_videos": isVideoEnabled ? "1" : "0",
            "cu_heic_to_jpg": CameraUploadManager.shouldConvertHEICPhoto ? "1" : "0",
            "cu_hevc_to_h264": CameraUploadManager.shouldConvertHEVCVideo ? "1" : "0",
            "cu_mobile_data": mobileData,
            "cu_given_up_files": Self.givenUpFilesGroup(Int(givenUpFiles))
        ]
    }

    private static func givenUpFilesGroup(_ count: Int) -> String {
        switch count {
        case 0: "0"
        case 1...10: "1-10"
        case 11...100: "11-100"
        default: "100+"
        }
    }
}
