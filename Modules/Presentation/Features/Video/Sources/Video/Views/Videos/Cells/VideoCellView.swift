import MEGADomain
import SwiftUI

struct VideoCellView: View {
    @ObservedObject var viewModel: VideoCellViewModel
    let videoConfig: VideoConfig
    
    var body: some View {
        VideoCellViewContent(
            previewEntity: viewModel.previewEntity,
            videoConfig: videoConfig,
            onTappedMoreOptions: viewModel.onTappedMoreOptions
        )
        .task {
            await viewModel.attemptLoadThumbnail()
        }
    }
}

struct VideoCellViewContent: View {
    @Environment(\.colorScheme) var colorScheme
    let previewEntity: VideoCellPreviewEntity
    let videoConfig: VideoConfig
    let onTappedMoreOptions: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
            leadingContent
                .frame(width: 142, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            centerContent
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            trailingContent
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: .infinity, idealHeight: 80, alignment: .leading)
    }
    
    private var leadingContent: some View {
        VideoThumbnailView(previewEntity: previewEntity, videoConfig: videoConfig)
    }
    
    private var centerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            VideoCellTitleText(
                videoConfig: videoConfig,
                title: previewEntity.title,
                labelImage: previewEntity.labelImage(source: videoConfig.rowAssets.labelAssets)
            )
            
            HStack(alignment: .center, spacing: 8) {
                
                Text(previewEntity.size)
                    .font(.caption)
                    .foregroundColor(videoConfig.colorAssets.secondaryTextColor)
                
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
                    .foregroundColor(videoConfig.colorAssets.secondaryTextColor)
                    .opacity(previewEntity.shouldShowCircleImage ? 1 : 0)
                
                Image(uiImage: videoConfig.rowAssets.publicLinkImage)
                    .font(.system(size: 12))
                    .foregroundColor(videoConfig.colorAssets.secondaryTextColor)
                    .opacity(previewEntity.isExported ? 1 : 0)
                
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
                .frame(maxHeight: .infinity)
        }
    }
    
    private var trailingContent: some View {
        Image(uiImage: videoConfig.rowAssets.moreImage)
            .foregroundColor(videoConfig.colorAssets.secondaryIconColor)
            .onTapGesture { onTappedMoreOptions() }
    }
}

// MARK: - Preview

#Preview {
    Group {
        VideoCellViewContent(previewEntity: .standard, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .favorite, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .hasPublicLink, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .hasLabel, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .all(title: .short), videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .all(title: .medium), videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .all(title: .long), videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .placeholder, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
    }
}
