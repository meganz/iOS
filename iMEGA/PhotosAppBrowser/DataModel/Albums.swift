
import Foundation
import Photos

final class Albums {
    private var items: [Album] = []
    
    // MARK:- Initializer.
    
    init() {
        loadAlbums()
    }
    
    // MARK:- Interface methods.

    func loadAlbums() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            items = fetchAlbums()
        }
    }

    func numberOfAlbums() -> Int {
       items.count
    }
    
    func album(at index: Int) -> Album {
       items[index]
    }
}

// MARK:- Private methods.

extension Albums {
    private var fetchOptions: PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return fetchOptions
    }
    
    private func smartAlbumCollection() -> PHFetchResult<PHAssetCollection> {
       PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                       subtype: .any,
                                                       options: nil)
    }
    
    private func albumCollection() -> PHFetchResult<PHAssetCollection> {
       PHAssetCollection.fetchAssetCollections(with: .album,
                                                       subtype: .any,
                                                       options: nil)
    }
    
    private func fetchAlbums() -> [Album] {
        var albums = fetch(fromCollection: smartAlbumCollection())
        albums.append(contentsOf: fetch(fromCollection: albumCollection()))
        albums.sort { album1, album2 in
            return album1.assetCount() > album2.assetCount()
        }
        return albums
    }
    
    private func fetch(fromCollection collection: PHFetchResult<PHAssetCollection>) -> [Album] {
       fetchAllValidAlbumNamesAndCount(album: collection).map { title, fetchResult in
           Album(title: title, fetchResult: fetchResult)
        }
    }
    
    private func fetchAllValidAlbumNamesAndCount(album: PHFetchResult<PHAssetCollection>) -> [(String, PHFetchResult<PHAsset>)] {
        var result: [(String, PHFetchResult<PHAsset>)] = []
        
        album.enumerateObjects { (collection, index , stop) in
            let photosInAlbum = PHAsset.fetchAssets(in: collection, options: self.fetchOptions)
            
            if let title = collection.localizedTitle, photosInAlbum.count > 0 {
                result.append((title, photosInAlbum))
            }
        }
        
        return result
    }
}
