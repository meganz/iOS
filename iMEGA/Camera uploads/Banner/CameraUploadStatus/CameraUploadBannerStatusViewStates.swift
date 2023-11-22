import Foundation
import SwiftUI

enum CameraUploadBannerStatusViewStates {
    case uploadInProgress(numberOfFilesPending: Int)
    case uploadPaused(reason: CameraUploadBannerStatusUploadPausedReason)
    case uploadPartialCompleted(reason: CameraUploadBannerStatusPartiallyCompletedReason)
    case uploadCompleted
}

enum CameraUploadBannerStatusPartiallyCompletedReason {
    case videoUploadIsNotEnabled(pendingVideoUploadCount: Int)
    case photoLibraryLimitedAccess
}

enum CameraUploadBannerStatusUploadPausedReason {
    case noWifiConnection(numberOfFilesPending: Int)
}
