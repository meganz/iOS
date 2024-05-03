import MEGADesignToken
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct AlbumCoverPickerPhotoCell: View {
    @ObservedObject var viewModel: AlbumCoverPickerPhotoCellViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            image()
            
            SingleSelectionCheckmarkView(markedSelected: viewModel.isSelected)
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
}

extension AlbumCoverPickerPhotoCell: Equatable {
    static func == (lhs: AlbumCoverPickerPhotoCell, rhs: AlbumCoverPickerPhotoCell) -> Bool {
        true // we are taking over the update of the view
    }
}
