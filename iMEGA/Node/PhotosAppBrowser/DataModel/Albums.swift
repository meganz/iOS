import Foundation
import MEGAPermissions
import Photos

protocol AlbumsDelegate: AnyObject {
    func albumAdded(_ album: Album, atIndex index: Int)
    func albumRemoved(_ album: Album, atIndex index: Int)
    func albumModified(_ album: Album, atIndex index: Int)
    func albumsReplaced()
}

// this protocol contains all points where we are interacting
// with photos framework so that we can easily test all interactions
protocol PhotoLibraryProviding {
    func register(_ observer: any PHPhotoLibraryChangeObserver)
    func unregisterChangeObserver(_ observer: any PHPhotoLibraryChangeObserver)
    func fetchAssets(
        in assetCollection: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset>
    
    func enumerateCollection(collection: PHFetchResult<PHAssetCollection>, block: @escaping (PHAssetCollection) -> Void)
}

extension PHPhotoLibrary: PhotoLibraryProviding {
    func enumerateCollection(
        collection: PHFetchResult<PHAssetCollection>,
        block: @escaping (PHAssetCollection) -> Void) {
        collection.enumerateObjects { _collection, _, _ in
            block(_collection)
        }
    }
    
    func fetchAssets(
        in assetCollection: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(in: assetCollection, options: options)
    }
    
}

final class Albums: NSObject {
    private var albums: [Album] = []
    private var emptyAlbums: [Album] = []
    
    weak var delegate: (any AlbumsDelegate)?
    
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
    
    private let loadAlbumsQueue = DispatchQueue(label: "nz.mega.PhotoAppBrowser.loadAlbums")

    var isEmpty: Bool {
        albums.isEmpty
    }
    
    // MARK: - Initializer.
    
    let permissionHandler: any DevicePermissionsHandling
    let photoLibrary: any PhotoLibraryProviding
    
    init(
        permissionHandler: some DevicePermissionsHandling,
        photoLibraryRegisterer: some PhotoLibraryProviding
    ) {
        self.permissionHandler = permissionHandler
        self.photoLibrary = photoLibraryRegisterer
        super.init()
    }
    
    /// Load albums in a background serial queue
    /// - Parameter completion: callback after the loading finishes. It will be called on main thread
    func loadAlbums(completion: @escaping () -> Void) {
        loadAlbumsQueue.async { [weak self] in
            guard let self else { return }
            self.loadAlbums()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("Do not use this initializer")
    }
    
    deinit {
        if !albums.isEmpty {
            photoLibrary.unregisterChangeObserver(self)
        }
    }
    
    // MARK: - Interface methods.

    private func loadAlbums() {
        
        let status = permissionHandler.photoLibraryAuthorizationStatus
        // This class was initially written in iOS > 14 when status
        // .limited was not added yet. The PHPhotoLibrary API used initially got deprecated
        // but until we used it, it was still not returning .limited value even though,
        // this was what user has selected It was returning .authorized value.
        // When later on, we started using non-deprecated API to get authorization status, code below was
        // broken, as it was not trying to load albums when .limited access was provided by the user
        if status == .authorized || status == .limited {
            populateAlbums()
            photoLibrary.register(self)
        }
    }

    func numberOfAlbums() -> Int {
       albums.count
    }
    
    func album(at index: Int) -> Album {
       albums[index]
    }
}

// MARK: - Private methods.

extension Albums {
    private func populateAlbums() {
        populate(fromCollection: smartAlbumFetchResult)
        populate(fromCollection: albumFetchResult)
        sortAlbums()
    }
    
    private func populate(fromCollection collection: PHFetchResult<PHAssetCollection>) {
        // the enumerateObjects on collection does not run on CI probably due to not provided authorization
        // extracted this to the protocol interface for photy library so that we can easily run on any machine
        
        photoLibrary.enumerateCollection(collection: collection) { assetCollection in
            let fetchResult = self.photoLibrary.fetchAssets(
                in: assetCollection,
                options: self.fetchOptions
            )
            
            if let title = assetCollection.localizedTitle {
                let album = Album(
                    title: title,
                    subType: assetCollection.assetCollectionSubtype,
                    fetchResult: fetchResult
                ) { [weak self] album in
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
                if album.assetCount() == 0 {
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
