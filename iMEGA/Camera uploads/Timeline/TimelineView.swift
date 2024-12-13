import ContentLibraries
import MEGASwiftUI
import SwiftUI

struct TimelineView: View {
    
    @ObservedObject var cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel
    @ObservedObject var photoLibraryContentViewModel: PhotoLibraryContentViewModel
    @ObservedObject var timelineViewModel: TimeLineViewModel

    let router: any PhotoLibraryContentViewRouting
    let onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?
    
    @State private var cameraUploadBannerStatusSize: CGSize = .zero
    
    init(photoLibraryContentViewModel: PhotoLibraryContentViewModel,
         timelineViewModel: TimeLineViewModel,
         router: any PhotoLibraryContentViewRouting,
         onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?) {
        self.cameraUploadStatusBannerViewModel = timelineViewModel.cameraUploadStatusBannerViewModel
        self.photoLibraryContentViewModel = photoLibraryContentViewModel
        self.timelineViewModel = timelineViewModel
        self.router = router
        self.onFilterUpdate = onFilterUpdate
        self.cameraUploadBannerStatusSize = cameraUploadBannerStatusSize
    }
    
    var body: some View {
        PhotoLibraryContentView(
            viewModel: photoLibraryContentViewModel,
            router: router,
            onFilterUpdate: onFilterUpdate)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top, content: cameraUploadBannerStatusView)
    }
    
    @ViewBuilder
    private func cameraUploadBannerStatusView() -> some View {
        CameraUploadBannerStatusView(previewEntity: cameraUploadStatusBannerViewModel.cameraUploadBannerStatusViewState.toPreviewEntity()) {
            cameraUploadStatusBannerViewModel.tappedCameraUploadBannerStatus()
        }
        .opacity(cameraUploadStatusBannerViewModel.cameraUploadStatusShown ? 1 : 0)
        .offset(y: cameraUploadStatusBannerViewModel.cameraUploadStatusShown ? 0 : -cameraUploadBannerStatusSize.height)
        .animation(.bouncy(duration: 1), value: cameraUploadStatusBannerViewModel.cameraUploadStatusShown)
        .alertPhotosPermission(isPresented: $cameraUploadStatusBannerViewModel.showPhotoPermissionAlert)
        .determineViewSize { @Sendable in cameraUploadBannerStatusSize = $0 }
        .throwingTask { try await cameraUploadStatusBannerViewModel.monitorCameraUploadStatus() }
        .throwingTask { try await cameraUploadStatusBannerViewModel.handleCameraUploadAutoDismissal() }
    }
}
