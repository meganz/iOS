import SwiftUI

@available(iOS 14.0, *)
struct PhotoCellContent: View {
    @ObservedObject var viewModel: PhotoCellViewModel
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.isSelected.toggle()
    }}
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PhotoCellImage(container: viewModel.thumbnailContainer,
                           aspectRatio: viewModel.currentZoomScaleFactor == .one ? nil : 1)
            
            if viewModel.editMode.isEditing {
                CheckMarkView(markedSelected: viewModel.isSelected)
                    .offset(x: -5, y: -5)
            }
        }
        .favorite(viewModel.isFavorite)
        .videoDuration(viewModel.isVideo, duration: viewModel.duration, with: viewModel.currentZoomScaleFactor)
        .gesture(viewModel.editMode.isEditing ? tap : nil)
        .onAppear {
            viewModel.loadThumbnailIfNeeded()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}
