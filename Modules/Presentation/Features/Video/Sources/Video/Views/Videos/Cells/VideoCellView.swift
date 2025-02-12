import MEGADesignToken
import MEGADomain
import MEGAPresentation
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
        VideoCellViewContent(
            mode: viewModel.mode,
            previewEntity: viewModel.previewEntity,
            videoConfig: videoConfig,
            reorderVideosInVideoPlaylistContentEnabled: viewModel.reorderVideosInVideoPlaylistContentEnabled,
            isSelected: $viewModel.isSelected,
            onTappedCheckMark: onTappedCheckMark,
            onTappedCell: onTappedCell,
            onTappedMoreOptions: viewModel.onTappedMoreOptions
        )
        .throwingTask { try await viewModel.attemptLoadThumbnail() }
        .task { await viewModel.monitorInheritedSensitivityChanges() }
    }
    
    private func onTappedCell() {
        if selection.editMode.isEditing {
            onTappedCheckMark()
        } else {
            viewModel.onCellTapped()
        }
    }
}

struct VideoCellViewContent: View {
    @Environment(\.colorScheme) var colorScheme
    let mode: VideoCellViewModel.Mode
    let previewEntity: VideoCellPreviewEntity
    let videoConfig: VideoConfig
    let reorderVideosInVideoPlaylistContentEnabled: Bool
    let isSelected: Binding<Bool>
    let onTappedCheckMark: () -> Void
    let onTappedCell: () -> Void
    let onTappedMoreOptions: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
            leftControlView
            
            Button {
                onTappedCell()
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    leadingContent
                        .frame(width: 142, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    centerContent
                        .padding(0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    if mode != .selection {
                        trailingContent
                            .frame(width: 24, height: 24)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NoHighlightButtonStyle())
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
                searchText: previewEntity.searchText,
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

            if let description = previewEntity.makeDescriptionAttributedString(
                withPrimaryTextColor: videoConfig.colorAssets.secondaryTextColor,
                highlightedTextColor: videoConfig.colorAssets.highlightedTextColor
            ) {
                Text(description)
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        Image(uiImage: videoConfig.rowAssets.moreImage)
            .foregroundStyle(videoConfig.colorAssets.secondaryIconColor)
            .onTapGesture { onTappedMoreOptions() }
    }
    
    private var checkMarkView: some View {
        Button {
            onTappedCheckMark()
        } label: {
            CheckMarkView(
                markedSelected: isSelected.wrappedValue,
                foregroundColor: isSelected.wrappedValue ? TokenColors.Support.success.swiftUI : TokenColors.Border.strong.swiftUI
            )
        }
    }
    
    private var dragIndicatorView: some View {
        Image(uiImage: videoConfig.rowAssets.grabberIconImage.withRenderingMode(.alwaysTemplate))
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .padding(.leading, 10)
    }
    
    @ViewBuilder
    private var leftControlView: some View {
        switch mode {
        case .selection:
            checkMarkView
                .padding(.leading, 10)
        case .reorder where reorderVideosInVideoPlaylistContentEnabled:
            dragIndicatorView
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    Group {
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .standard,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .favorite,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .selection,
            previewEntity: .hasPublicLink,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(true),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .reorder,
            previewEntity: .hasPublicLink,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(true),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .hasLabel,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .all(title: .short),
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .all(title: .medium),
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .all(title: .long),
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
        
        VideoCellViewContent(
            mode: .plain,
            previewEntity: .placeholder,
            videoConfig: .preview,
            reorderVideosInVideoPlaylistContentEnabled: false,
            isSelected: .constant(false),
            onTappedCheckMark: {},
            onTappedCell: {},
            onTappedMoreOptions: {}
        )
    }
    .frame(height: 80)
}
