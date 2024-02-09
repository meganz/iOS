import MEGADomain
import MEGASwift
import SwiftUI

struct CameraUploadStatusButtonView: View {
    @ObservedObject var viewModel: CameraUploadStatusButtonViewModel
    
    var body: some View {
        Button(action: viewModel.onTapped) {
            CameraUploadStatusImageView(viewModel: viewModel.imageViewModel)
                .task {
                    await viewModel.monitorCameraUpload()
                }
                .onDisappear {
                    viewModel.onViewDisappear()
                }
        }
    }
}
