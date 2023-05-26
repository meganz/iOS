import SwiftUI
import MEGASwiftUI

struct AlbumCell: View {
    @StateObject var viewModel: AlbumCellViewModel
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.onAlbumTap()
    }}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: viewModel.isLoading ? .center : .bottomTrailing) {
                PhotoCellImage(container: viewModel.thumbnailContainer, bgColor: Color(Colors.General.Gray.ebebeb.color))
                    .cornerRadius(6)
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
                
                CheckMarkView(
                    markedSelected: viewModel.isSelected,
                    foregroundColor: viewModel.isSelected ? .green : Color(Colors.Photos.photoSeletionBorder.color)
                )
                .offset(x: -5, y: -5)
                .opacity(viewModel.shouldShowEditStateOpacity)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                
                Text("\(viewModel.numberOfNodes)")
                    .font(.footnote)
            }
        }
        .opacity(viewModel.opacity)
        .onAppear {
            viewModel.loadAlbumThumbnail()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .gesture(viewModel.editMode.isEditing ? tap : nil)
    }
}
