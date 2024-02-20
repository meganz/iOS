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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding([.top, .bottom], 8)
    }
    
    private var leadingContent: some View {
        VideoThumbnailView(previewEntity: previewEntity, videoConfig: videoConfig)
    }
    
    private var centerContent: some View {
        
        VStack(alignment: .leading, spacing: 4) {
            
            HStack {
                Text(previewEntity.title)
                    .font(.subheadline)
                    .foregroundColor(videoConfig.colorAssets.primaryTextColor)
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .topLeading)
                
                if let labelImage = previewEntity.labelImage(source: videoConfig.rowAssets.labelAssets) {
                    Image(uiImage: labelImage)
                        .font(.system(size: 12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
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
                    .opacity(previewEntity.isPublicLink ? 1 : 0)
                
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        VideoCellViewContent(previewEntity: .all, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
        VideoCellViewContent(previewEntity: .placeholder, videoConfig: .preview, onTappedMoreOptions: {})
            .frame(height: 80)
    }
}
