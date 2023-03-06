
import SwiftUI
import Combine
import MEGADomain

final class AlbumSelection: ObservableObject {
    @Published var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published var albums = [HandleEntity: AlbumEntity]()
    
    @Published var allSelected = false {
        willSet {
            if !newValue {
                albums.removeAll()
            }
        }
    }
    
    func setSelectedAlbums(_ albums: [AlbumEntity]) {
        self.albums = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, $0) })
    }
    
    func isAlbumSelected(_ album: AlbumEntity) -> Bool {
        albums[album.id] != nil
    }
}

