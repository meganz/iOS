import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoCellContent: View {
    @ObservedObject var viewModel: PhotoCellViewModel
    var isSelfSizing = true
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.select()
    }}
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            image()
            
            checkMarkView
                .offset(x: -5, y: -5)
                .opacity(viewModel.shouldShowEditState ? 1 : 0)
        }
        .favorite(viewModel.shouldShowFavorite)
        .videoDuration(PhotoCellVideoDurationViewModel(isVideo: viewModel.isVideo, duration: viewModel.duration, scaleFactor: viewModel.currentZoomScaleFactor))
        .opacity(viewModel.shouldApplyContentOpacity ? 0.4 : 1)
        .gesture(viewModel.editMode.isEditing ? tap : nil)
        .task { await viewModel.startLoadingThumbnail() }
    }
    
    private var checkMarkView: some View {
        if isDesignTokenEnabled {
            CheckMarkView(
                markedSelected: viewModel.isSelected,
                iconForegroundColor: TokenColors.Icon.inverseAccent.swiftUI,
                foregroundColor: viewModel.isSelected ? TokenColors.Components.selectionControl.swiftUI : Color.clear,
                borderColor: viewModel.isSelected ? Color.clear : TokenColors.Border.strong.swiftUI
            )
        } else {
            CheckMarkView(
                markedSelected: viewModel.isSelected,
                foregroundColor: viewModel.isSelected ? MEGAAppColor.Green._34C759.color : MEGAAppColor.Photos.photoSelectionBorder.color
            )
        }
    }
    
    @ViewBuilder
    private func image() -> some View {
        if isSelfSizing {
            PhotoCellImage(container: viewModel.thumbnailContainer,
                           aspectRatio: viewModel.currentZoomScaleFactor == .one ? nil : 1)
        } else {
            Color.clear
                .overlay(PhotoCellImage(container: viewModel.thumbnailContainer))
        }
    }
}
