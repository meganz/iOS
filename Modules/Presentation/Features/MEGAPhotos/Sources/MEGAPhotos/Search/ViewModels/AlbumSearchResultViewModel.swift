import ContentLibraries
import MEGADomain
import SwiftUI

@MainActor
final class AlbumSearchResultViewModel: ObservableObject {
    let cellViewModels: [AlbumCellViewModel]
    @Binding var searchText: String
    @Published var selectedAlbum: AlbumEntity?
    
    init(cellViewModels: [AlbumCellViewModel],
         searchText: Binding<String>) {
        self.cellViewModels = cellViewModels
        _searchText = searchText
    }
}
