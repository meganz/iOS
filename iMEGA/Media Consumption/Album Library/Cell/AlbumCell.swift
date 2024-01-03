import MEGASwiftUI
import SwiftUI

struct AlbumCell: View {
    @StateObject var viewModel: AlbumCellViewModel
    
    private var tap: some Gesture { TapGesture().onEnded { _ in
        viewModel.onAlbumTap()
    }}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: viewModel.isLoading ? .center : .bottomTrailing) {
                PhotoCellImage(container: viewModel.thumbnailContainer, bgColor: MEGAAppColor.Gray._EBEBEB.color)
                    .cornerRadius(6)
                
                GeometryReader { geo in
                    LinearGradient(colors: [MEGAAppColor.Black._000000.color, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height / 2)
                        .cornerRadius(5, corners: [.topLeft, .topRight])
                        .opacity(viewModel.isLinkShared ? 0.4 : 0.0)
                }
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
                
                VStack {
                    SharedLinkView()
                        .offset(x: 2, y: 0)
                        .opacity(viewModel.isLinkShared ? 1.0 : 0.0)
                    
                    Spacer()
                    
                    CheckMarkView(
                        markedSelected: viewModel.isSelected,
                        foregroundColor: viewModel.isSelected ? MEGAAppColor.Green._34C759.color : MEGAAppColor.Photos.photoSelectionBorder.color
                    )
                    .offset(x: -5, y: -5)
                    .opacity(viewModel.shouldShowEditStateOpacity)
                }
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
        .task {
            await viewModel.loadAlbumThumbnail()
        }
        .gesture(viewModel.editMode.isEditing ? tap : nil)
    }
}
