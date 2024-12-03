import Combine
import MEGADomain
import SwiftUI

public final class AlbumSelection: ObservableObject {
    public enum SelectionMode {
        case single
        case multiple
    }
    
    @Published public var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published public private(set) var albums = [HandleEntity: AlbumEntity]()
    
    @Published public var allSelected = false {
        willSet {
            if !newValue {
                albums.removeAll()
            }
        }
    }
    
    private let mode: SelectionMode
    
    public init(mode: SelectionMode = .multiple) {
        self.mode = mode
    }
    
    public func setSelectedAlbums(_ albums: [AlbumEntity]) {
        switch mode {
        case .single:
            if let firstAlbum = albums.first {
                self.albums = [firstAlbum.id: firstAlbum]
            } else {
                self.albums.removeAll()
            }
        case .multiple:
            self.albums = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, $0) })
        }
    }
    
    func isAlbumSelected(_ album: AlbumEntity) -> Bool {
        albums[album.id] != nil
    }
    
    func toggle(_ album: AlbumEntity) {
        if isAlbumSelected(album) {
            if mode == .single {
                albums.removeAll()
            } else {
                albums[album.id] = nil
            }
        } else {
            if mode == .single {
                albums.removeAll()
            }
            albums[album.id] = album
        }
    }
}

public extension AlbumSelection {
    
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
    
    func isAlbumSelectedPublisher(album: AlbumEntity) -> AnyPublisher<Bool, Never> {
        $allSelected
            .combineLatest($albums.map({ $0[album.id] != nil }))
            .map { isAllSelected, isAlbumSelected in
                isAllSelected || isAlbumSelected
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
