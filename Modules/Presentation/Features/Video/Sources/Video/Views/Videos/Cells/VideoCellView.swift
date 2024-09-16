import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct VideoCellView: View {
    @StateObject private var viewModel: VideoCellViewModel
    @StateObject private var selection: VideoSelection
    private let onTappedCheckMark: () -> Void
    private let videoConfig: VideoConfig
    
    init(
        viewModel: @autoclosure @escaping () -> VideoCellViewModel,
        selection: @autoclosure @escaping () -> VideoSelection,
        onTappedCheckMark: @escaping () -> Void,
        videoConfig: VideoConfig
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _selection = StateObject(wrappedValue: selection())
        self.onTappedCheckMark = onTappedCheckMark
        self.videoConfig = videoConfig
    }
    
    var body: some View {
        Button {
            if selection.editMode.isEditing {
                onTappedCheckMark()
            } else {
                viewModel.onCellTapped()
            }
        } label: {
            VideoCellViewContent(
                previewEntity: viewModel.previewEntity,
                videoConfig: videoConfig,
                editMode: $selection.editMode,
                isSelected: $viewModel.isSelected,
                onTappedMoreOptions: viewModel.onTappedMoreOptions
            )
            .contentShape(Rectangle())
            .throwingTask { try await viewModel.attemptLoadThumbnail() }
            .task { await viewModel.monitorInheritedSensitivityChanges() }
        }
        .buttonStyle(NoHighlightButtonStyle())
    }
}

struct VideoCellViewContent: View {
    @Environment(\.colorScheme) var colorScheme
    let previewEntity: VideoCellPreviewEntity
    let videoConfig: VideoConfig
    let editMode: Binding<EditMode>
    let isSelected: Binding<Bool>
    let onTappedMoreOptions: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
            if editMode.wrappedValue.isEditing {
                checkMarkView
                    .padding(.leading, 10)
            }
            
            leadingContent
                .frame(width: 142, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            centerContent
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            if !editMode.wrappedValue.isEditing {
                trailingContent
                    .frame(width: 24, height: 24)
            }
            
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
                labelImage: previewEntity.labelImage(source: videoConfig.rowAssets.labelAssets),
                downloadedImage: previewEntity.downloadedImage(source: videoConfig.rowAssets)
            )
            
            HStack(alignment: .center, spacing: 8) {
                
                Text(previewEntity.size)
                    .font(.caption)
                    .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
                
                Image(systemName: "circle.fill")
                    .font(.system(size: 4))
                    .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
                    .opacity(previewEntity.shouldShowCircleImage ? 1 : 0)
                
                Image(uiImage: videoConfig.rowAssets.publicLinkImage)
                    .font(.system(size: 12))
                    .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
                    .opacity(previewEntity.isExported ? 1 : 0)
                
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
                .frame(maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        Image(uiImage: videoConfig.rowAssets.moreImage)
            .foregroundStyle(videoConfig.colorAssets.secondaryIconColor)
            .onTapGesture { onTappedMoreOptions() }
    }
    
    private var checkMarkView: some View {
        CheckMarkView(
            markedSelected: isSelected.wrappedValue,
            foregroundColor: isSelected.wrappedValue ? TokenColors.Support.success.swiftUI : TokenColors.Border.strong.swiftUI
        )
    }
}

// MARK: - Preview

#Preview {
    Group {
        VideoCellViewContent(
            previewEntity: .standard,
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .favorite,
            videoConfig: .preview,
            editMode: .constant(.active),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .hasPublicLink,
            videoConfig: .preview,
            editMode: .constant(.active),
            isSelected: .constant(true),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .hasLabel,
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .all(title: .short),
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .all(title: .medium),
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .all(title: .long),
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            previewEntity: .placeholder,
            videoConfig: .preview,
            editMode: .constant(.inactive),
            isSelected: .constant(false),
            onTappedMoreOptions: {}
        )
    }
    .frame(height: 80)
}
