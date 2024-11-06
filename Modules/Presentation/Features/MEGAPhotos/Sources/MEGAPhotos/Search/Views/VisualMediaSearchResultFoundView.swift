import ContentLibraries
import MEGADomain
import SwiftUI

struct VisualMediaSearchResultFoundView: View {
    let albumCellViewModels: [AlbumCellViewModel]
    let photos: [NodeEntity]
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if albumCellViewModels.isNotEmpty {
                AlbumSearchResultView(
                    viewModel: .init(
                        cellViewModels: albumCellViewModels,
                        searchText: $searchText)
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    VisualMediaSearchResultFoundView(
        albumCellViewModels: [],
        photos: [],
        searchText: .constant(""))
}
