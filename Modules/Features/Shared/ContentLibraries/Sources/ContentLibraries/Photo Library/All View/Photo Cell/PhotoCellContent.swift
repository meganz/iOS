import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoCellContent: View {
    @ObservedObject var viewModel: PhotoCellViewModel
    var isSelfSizing = true
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.select()
    }}
    
    private var isMediaRevampEnabled: Bool {
        viewModel.isMediaRevamp
    }
    
    var body: some View {
        ZStack(alignment: isMediaRevampEnabled ? .topLeading : .bottomTrailing) {
            image()
            /// An overlayView to enhance visual selection thumbnail image. Requested by designers to not use design tokens for this one.
                .overlay(Color.black.opacity(viewModel.isSelected ? 0.2 : 0.0))
            
            checkMarkView
                .offset(x: isMediaRevampEnabled ? 5 : -5, y: isMediaRevampEnabled ? 5 : -5)
                .opacity(viewModel.shouldShowEditState ? 1 : 0)
        }
        .favorite(viewModel.shouldShowFavorite, isMediaRevamp: isMediaRevampEnabled)
        .videoDuration(PhotoCellVideoDurationViewModel(isVideo: viewModel.isVideo, duration: viewModel.duration, scaleFactor: viewModel.currentZoomScaleFactor))
        .opacity(viewModel.shouldApplyContentOpacity ? 0.4 : 1)
        .gesture(viewModel.editMode.isEditing ? tap : nil)
        .task { await viewModel.startLoadingThumbnail() }
        .task {
            if #available(iOS 16, *) {
                await viewModel.monitorInheritedSensitivityChanges()
            } else {
                await viewModel.monitorPhotoSensitivityChanges()
            }
        }
    }
    
    private var checkMarkForegroundColor: Color {
        if viewModel.isSelected {
            return isMediaRevampEnabled ? TokenColors.Icon.accent.swiftUI : TokenColors.Support.success.swiftUI
        } else {
            return TokenColors.Icon.onColor.swiftUI
        }
    }

    private var checkMarkView: some View {
        CheckMarkView(
            markedSelected: viewModel.isSelected,
            foregroundColor: checkMarkForegroundColor,
            isMediaRevamp: isMediaRevampEnabled
        )
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
