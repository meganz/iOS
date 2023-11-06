import MEGADomain
import MEGASwift
import SwiftUI

struct CameraUploadStatusButtonView: View {
    @ObservedObject var viewModel: CameraUploadStatusButtonViewModel
    
    var body: some View {
        Button {
            // Handle pressed in CC-5455
        } label: {
            CameraUploadStatusImageView(viewModel: viewModel.imageViewModel)
                .taskForiOS14 {
                    await viewModel.monitorCameraUpload()
                }
        }
    }
}
