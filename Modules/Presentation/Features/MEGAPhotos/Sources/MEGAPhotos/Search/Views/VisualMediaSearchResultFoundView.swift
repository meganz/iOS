import ContentLibraries
import MEGADomain
import SwiftUI

struct VisualMediaSearchResultFoundView: View {
    let albums: [AlbumCellViewModel]
    let photos: [PhotoSearchResultItemViewModel]
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if albums.isNotEmpty {
                AlbumSearchResultView(
                    viewModel: .init(
                        albums: albums,
                        searchText: $searchText)
                )
            }
            
            PhotoSearchResultView(photos: photos)
                .opacity(photos.isNotEmpty ? 1: 0)
            
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    VisualMediaSearchResultFoundView(
        albums: [],
        photos: [],
        searchText: .constant(""))
}
