import SwiftUI

struct AlbumCell: View {
    @StateObject var viewModel: AlbumCellViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                PhotoCellImage(container: viewModel.thumbnailContainer, bgColor: Color(Colors.General.Gray.ebebeb.color))
                    .cornerRadius(6)
                
                ProgressView()
                    .opacity(viewModel.isLoading ? 1.0 : 0.0)
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
        .onAppear {
            viewModel.loadAlbumThumbnail()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}
