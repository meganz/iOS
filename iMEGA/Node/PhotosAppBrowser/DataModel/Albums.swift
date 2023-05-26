
import Foundation
import Photos

protocol AlbumsDelegate: AnyObject {
    func albumAdded(_ album: Album, atIndex index: Int)
    func albumRemoved(_ album: Album, atIndex index: Int)
    func albumModified(_ album: Album, atIndex index: Int)
    func albumsReplaced()
}

final class Albums: NSObject {
    private var albums: [Album] = []
    private var emptyAlbums: [Album] = []
    
    weak var delegate: AlbumsDelegate?
    
    private lazy var smartAlbumFetchResult: PHFetchResult<PHAssetCollection> = {
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                subtype: .any,
                                                options: nil)
    }()
    
    private lazy var albumFetchResult: PHFetchResult<PHAssetCollection> = {
        PHAssetCollection.fetchAssetCollections(with: .album,
                                                subtype: .any,
                                                options: nil)
    }()
    
    private lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return fetchOptions
    }()

    // MARK:- Initializer.
    
    override init() {
        super.init()
        loadAlbums()
    }
    
    deinit {
        if !albums.isEmpty {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    // MARK:- Interface methods.

    func loadAlbums() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            populateAlbums()
            PHPhotoLibrary.shared().register(self)
        }
    }

    func numberOfAlbums() -> Int {
       albums.count
    }
    
    func album(at index: Int) -> Album {
       albums[index]
    }
}

// MARK:- Private methods.

extension Albums {
    private func populateAlbums()  {
        populate(fromCollection: smartAlbumFetchResult)
        populate(fromCollection: albumFetchResult)
        sortAlbums()
    }
    
    private func populate(fromCollection collection: PHFetchResult<PHAssetCollection>) {
        collection.enumerateObjects { (collection, _, _) in
            let fetchResult = PHAsset.fetchAssets(in: collection, options: self.fetchOptions)
            
            if let title = collection.localizedTitle {
                let album = Album(title: title, subType: collection.assetCollectionSubtype, fetchResult: fetchResult) { [weak self] album in
                    self?.updated(album: album)
                }
                
                if fetchResult.count > 0 {
                    self.albums.append(album)
                } else {
                    self.emptyAlbums.append(album)
                }
            }
        }
    }
    
    private func sortAlbums() {
        albums.sort { album1, album2 in
            album1.assetCount() > album2.assetCount()
        }
    }
    
    private func updated(album: Album) {
        OperationQueue.main.addOperation { [weak self] in
            guard let `self` = self else { return }
            
            if let index = self.emptyAlbums.firstIndex(of: album), album.assetCount() > 0 {
                self.albums.append(album)
                self.emptyAlbums.remove(at: index)
                self.delegate?.albumAdded(album, atIndex: self.albums.count - 1)
            } else if let index = self.albums.firstIndex(of: album) {
                if album.assetCount() == 0  {
                    self.emptyAlbums.append(album)
                    self.albums.remove(at: index)
                    self.delegate?.albumRemoved(album, atIndex: index)
                } else {
                    self.delegate?.albumModified(album, atIndex: index)
                }
            }
        }
    }
}

extension Albums: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        photoLibraryChanged(changeInstance, collectionResult: &smartAlbumFetchResult)
        photoLibraryChanged(changeInstance, collectionResult: &albumFetchResult)
    }
    
    private func photoLibraryChanged(_ changeInstance: PHChange, collectionResult: inout PHFetchResult<PHAssetCollection>) {
        if let changeDetails = changeInstance.changeDetails(for: collectionResult) {
            collectionResult = changeDetails.fetchResultAfterChanges
            OperationQueue.main.addOperation {
                self.delegate?.albumsReplaced()
            }
        }
    }
}
