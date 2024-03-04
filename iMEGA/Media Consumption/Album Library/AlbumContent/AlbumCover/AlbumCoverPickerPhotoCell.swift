import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct AlbumCoverPickerPhotoCell: View {
    @ObservedObject var viewModel: AlbumCoverPickerPhotoCellViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            image()
            
            singleSelectionCheckmarkView()
        }
        .favorite(viewModel.shouldShowFavorite)
        .videoDuration(PhotoCellVideoDurationViewModel(isVideo: viewModel.isVideo, duration: viewModel.duration))
        .onTapGesture(count: 1) {
            viewModel.onPhotoSelect()
        }
        .task { await viewModel.startLoadingThumbnail() }
        .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : nil)
    }
    
    @ViewBuilder
    private func image() -> some View {
        PhotoCellImage(container: viewModel.thumbnailContainer)
    }
    
    private func singleSelectionCheckmarkView() -> some View {
        Group {
            if isDesignTokenEnabled {
                CheckMarkView(
                    markedSelected: viewModel.isSelected,
                    iconForegroundColor: TokenColors.Icon.inverseAccent.swiftUI,
                    foregroundColor: viewModel.isSelected ? TokenColors.Components.selectionControl.swiftUI : Color.clear,
                    borderColor: Color.clear
                )
            } else {
                SingleSelectionCheckmarkView(markedSelected: viewModel.isSelected)
            }
        }
        .offset(x: -5, y: -5)
    }
}

extension AlbumCoverPickerPhotoCell: Equatable {
    static func == (lhs: AlbumCoverPickerPhotoCell, rhs: AlbumCoverPickerPhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
