import MEGASwiftUI
import SwiftUI

@MainActor
final class TimeLineViewModel: ObservableObject, SnackBarObservablePresenting {
    
    @Published var snackBar: SnackBar?
    @Published var cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel

    init(cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel) {
        self.cameraUploadStatusBannerViewModel = cameraUploadStatusBannerViewModel
    }
    
    func show(snack: SnackBar) {
        self.snackBar = snack
    }
}
