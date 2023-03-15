import SwiftUI

struct AlbumCoverPickerPhotoCell: View {
    @ObservedObject var viewModel: AlbumCoverPickerPhotoCellViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            image()
            
            SingleSelectionCheckmarkView(markedSelected: viewModel.isSelected)
                .offset(x: -5, y: -5)
        }
        .favorite(viewModel.shouldShowFavorite)
        .videoDuration(PhotoCellVideoDurationViewModel(isVideo: viewModel.isVideo, duration: viewModel.duration))
        .onTapGesture(count: 1) {
            viewModel.onPhotoSelect()
        }
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
