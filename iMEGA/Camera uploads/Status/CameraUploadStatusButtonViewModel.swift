import SwiftUI

enum CameraUploadStatus: Equatable {
    case enable
    case sync
    // progress between 0.0 and 1.0
    case uploading(progress: Float)
    case completed
    case idle
    case warning
}

final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    @Published private(set) var status: CameraUploadStatus
    
    var progress: Float? {
        switch status {
        case .uploading(let progress):
            return progress
        case .completed:
            return 1.0
        default:
            return nil
        }
    }
    
    var progressLineColor: Color {
        switch status {
        case .uploading:
            return Color(Colors.General.Blue._007Aff.color)
        case .completed:
            return Color(Colors.General.Green._34C759.color)
        default:
            return .clear
        }
    }
    
    var baseImageResource: ImageResource {
        switch status {
        case .enable:
            return .cuStatusEnable
        default:
            return .cuStatusUpload
        }
    }
    
    var statusImageResource: ImageResource? {
        switch status {
        case .enable:
            return nil
        case .sync:
            return .cuStatusUploadSync
        case .uploading:
            return .cuStatusUploadInProgressCheckMark
        case .completed:
            return .cuStatusUploadCompleteGreenCheckMark
        case .idle:
            return .cuStatusUploadIdleCheckMark
        case .warning:
            return .cuStatusUploadWarningCheckMark
        }
    }
    
    var shouldRotateStatusImage: Bool {
        status == .sync
    }

    init(status: CameraUploadStatus = .enable) {
        self.status = status
        super.init()
    }
}
