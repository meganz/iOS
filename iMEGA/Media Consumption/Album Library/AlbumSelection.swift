
import Combine
import MEGADomain
import SwiftUI

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

extension AlbumSelection {
    var isAlbumSelectedPublisher: AnyPublisher<Bool, Never> {
        $albums
            .map { $0.values.isNotEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    var isExportedAlbumSelectedPublisher: AnyPublisher<Bool, Never> {
        $albums.map {
            $0.values.contains(where: {
                if case .exported(let isExported) = $0.sharedLinkStatus {
                    return isExported
                }
                return false
            })
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
    
    var isOnlyExportedAlbumsSelectedPublisher: AnyPublisher <Bool, Never> {
        $albums.map {
            $0.values.count > 0 && $0.values.allSatisfy { album in
                album.isLinkShared == true
            }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
