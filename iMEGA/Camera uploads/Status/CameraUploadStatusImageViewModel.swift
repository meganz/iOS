import MEGAAssets
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
    
    var baseImage: Image {
        switch status {
        case .turnedOff:
            return MEGAAssets.Image.cuStatusEnable
        default:
            return MEGAAssets.Image.cuStatusUpload
        }
    }
    
    var statusImage: Image? {
        switch status {
        case .turnedOff:
            return nil
        case .checkPendingItemsToUpload:
            return MEGAAssets.Image.cuStatusUploadSync
        case .uploading:
            return MEGAAssets.Image.cuStatusUploadInProgressCheckMark
        case .completed:
            return MEGAAssets.Image.cuStatusUploadCompleteGreenCheckMark
        case .idle:
            return MEGAAssets.Image.cuStatusUploadIdleCheckMark
        case .warning:
            return MEGAAssets.Image.cuStatusUploadWarningCheckMark
        }
    }
    
    var shouldRotateStatusImage: Bool {
        status == .checkPendingItemsToUpload
    }
    
    init(status: CameraUploadStatus) {
        self.status = status
    }
}
