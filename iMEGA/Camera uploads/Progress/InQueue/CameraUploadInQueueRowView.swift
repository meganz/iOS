import MEGADesignToken
import SwiftUI

struct CameraUploadInQueueRowView: View {
    @ObservedObject var viewModel: CameraUploadInQueueRowViewModel
    
    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            CameraUploadThumbnailView(
                viewModel: viewModel.thumbnailViewModel)
            
            Text(viewModel.id)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .pageBackground()
    }
}
