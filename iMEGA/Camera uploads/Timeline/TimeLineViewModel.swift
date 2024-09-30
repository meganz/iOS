import Combine
import MEGASwiftUI
import SwiftUI

@MainActor
final class TimeLineViewModel: ObservableObject {
    
    @Published var cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel

    init(cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel) {
        self.cameraUploadStatusBannerViewModel = cameraUploadStatusBannerViewModel
    }
}
