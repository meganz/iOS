import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import UIKit

struct PhotoCellContent: View {
    @ObservedObject var viewModel: PhotoCellViewModel
    var isSelfSizing = true
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.select()
    }}

    private var longPress: some Gesture {
        LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.handleLongPress()
        }
    }
    
    private var shouldShowSelectionBorder: Bool {
        viewModel.isSelected && viewModel.shouldShowEditState
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            image()

            checkMarkView
                .offset(x: 5, y: 5)
                .opacity(viewModel.shouldShowEditState ? 1 : 0)
        }
        .border(shouldShowSelectionBorder ? TokenColors.Icon.accent.swiftUI : .clear, width: 2)
        .favorite(viewModel.shouldShowFavorite, useLegacyStyle: viewModel.useLegacyFavoriteStyle)
        .videoDuration(PhotoCellVideoDurationViewModel(isVideo: viewModel.isVideo, duration: viewModel.duration, scaleFactor: viewModel.currentZoomScaleFactor))
        .opacity(viewModel.shouldApplyContentOpacity ? 0.4 : 1)
        .gesture(viewModel.editMode.isEditing ? tap : nil)
        .gesture(viewModel.editMode.isEditing ? nil : longPress)
        // Keyed on the node identity so an in-place hydration (placeholder → real node via
        // `reconfigureItems`, which reuses the view identity) restarts the load against the real
        // node instead of keeping the placeholder's no-op task. See `nodeLoadIdentity`.
        .task(id: viewModel.nodeLoadIdentity) { await viewModel.startLoadingThumbnail() }
        .task(id: viewModel.nodeLoadIdentity) {
            if #available(iOS 16, *) {
                await viewModel.monitorInheritedSensitivityChanges()
            } else {
                await viewModel.monitorPhotoSensitivityChanges()
            }
        }
    }
    
    private var checkMarkForegroundColor: Color {
        viewModel.isSelected ? TokenColors.Icon.accent.swiftUI : TokenColors.Icon.onColor.swiftUI
    }

    private var checkMarkView: some View {
        CheckMarkView(
            markedSelected: viewModel.isSelected,
            foregroundColor: checkMarkForegroundColor,
            isMediaRevamp: true
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
