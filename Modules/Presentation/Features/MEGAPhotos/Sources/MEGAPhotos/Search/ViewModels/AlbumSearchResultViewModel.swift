import ContentLibraries
import MEGADomain
import SwiftUI

@MainActor
final class AlbumSearchResultViewModel: ObservableObject {
    let albums: [AlbumCellViewModel]
    @Binding var searchText: String
    @Published var selectedAlbum: AlbumEntity?
    
    init(albums: [AlbumCellViewModel],
         searchText: Binding<String>) {
        self.albums = albums
        _searchText = searchText
    }
}
