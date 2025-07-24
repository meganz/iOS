import Foundation
import SwiftUI

enum CameraUploadBannerStatusViewStates: Equatable {
    case uploadInProgress(numberOfFilesPending: UInt)
    case uploadPaused(reason: CameraUploadBannerStatusUploadPausedReason)
    case uploadPartialCompleted(reason: CameraUploadBannerStatusPartiallyCompletedReason)
    case uploadCompleted
}

enum CameraUploadBannerStatusPartiallyCompletedReason: Equatable {
    case videoUploadIsNotEnabled(pendingVideoUploadCount: UInt)
    case photoLibraryLimitedAccess
}

enum CameraUploadBannerStatusUploadPausedReason: Equatable {
    case noWifiConnection
    case noInternetConnection
    case lowBattery
    case highThermalState
}
