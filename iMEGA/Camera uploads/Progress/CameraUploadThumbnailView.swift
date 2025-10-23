import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct CameraUploadThumbnailView: View {
    @ObservedObject var viewModel: CameraUploadThumbnailViewModel
    
    var body: some View {
        Group {
            if let thumbnailImage = viewModel.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .shimmering()
            }
        }
        .frame(width: viewModel.thumbnailSize.width, height: viewModel.thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        .task {
            await viewModel.loadThumbnail()
        }
    }
}
