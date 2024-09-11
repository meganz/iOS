import MEGADesignToken
import SwiftUI

enum CameraUploadStatus: Equatable {
    case turnedOff
    case checkPendingItemsToUpload
    // progress between 0.0 and 1.0
    case uploading(progress: Float)
    case completed
    case idle
    case warning
}

final class CameraUploadStatusImageViewModel: ObservableObject {
    @Published var status: CameraUploadStatus
    
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
            TokenColors.Support.info.swiftUI
        case .completed:
            TokenColors.Support.success.swiftUI
        default: .clear
        }
    }
    
    var baseImageResource: ImageResource {
        switch status {
        case .turnedOff:
            return .cuStatusEnable
        default:
            return .cuStatusUpload
        }
    }
    
    var statusImageResource: ImageResource? {
        switch status {
        case .turnedOff:
            return nil
        case .checkPendingItemsToUpload:
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
        status == .checkPendingItemsToUpload
    }
    
    init(status: CameraUploadStatus) {
        self.status = status
    }
}
