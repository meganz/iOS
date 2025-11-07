import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct CameraUploadInProgressRowView: View {
    @ObservedObject var viewModel: CameraUploadInProgressRowViewModel
    
    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: TokenSpacing._3) {
                CameraUploadThumbnailView(
                    viewModel: viewModel.thumbnailViewModel)
                
                VStack(alignment: .leading, spacing: TokenSpacing._1) {
                    Text(viewModel.fileName)
                        .font(.body)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    
                    fileProgressInformation
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            
            ProgressView(value: viewModel.percentage)
                .progressViewStyle(.linear)
                .tint(TokenColors.Support.success.swiftUI)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .background(TokenColors.Background.surface1.swiftUI)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .pageBackground()
        .task {
            await viewModel.load()
        }
        .task {
            await viewModel.monitorUploadProgress()
        }
    }
    
    private var fileProgressInformation: some View {
        HStack(spacing: TokenSpacing._3) {
            Text(viewModel.fileProgress)
            Text(viewModel.uploadSpeed)
        }
        .font(.footnote)
        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }
}
