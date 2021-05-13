
import UIKit
import Photos

protocol AlbumDelegate: AnyObject {
    func didResetFetchResult()
    func didChange(removedIndexPaths: [IndexPath]?,
                   insertedIndexPaths: [IndexPath]?,
                   changedIndexPaths: [IndexPath]?)
}

final class Album: NSObject {
    let title: String
    private var fetchResult: PHFetchResult<PHAsset>
    typealias UpdatedFetchResultsHandler = ((Album) -> Void)
    private let updatedFetchResultsHandler: UpdatedFetchResultsHandler

    weak var delegate: AlbumDelegate?
    
    // MARK:- Initializer.

    init(title: String, fetchResult: PHFetchResult<PHAsset>, updatedFetchResultsHandler: @escaping UpdatedFetchResultsHandler) {
        self.title = title
        self.fetchResult = fetchResult
        self.updatedFetchResultsHandler = updatedFetchResultsHandler
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK:- Interface methods.
    
    func assetCount() -> Int {
       fetchResult.count
    }
    
    func asset(atIndex index: Int) -> PHAsset {
       fetchResult.object(at: index)
    }
    
    func index(asset: PHAsset) -> Int {
       fetchResult.index(of: asset)
    }
    
    // Fetches the first "count" asset from album.
    // Returns the max number of assets if count is greater than max
    func assets(count: Int) -> [PHAsset] {
        var assets: [PHAsset] = []

        fetchResult.enumerateObjects { asset, index, stop in
            assets.append(asset)
            if index == (count - 1)  {
                stop.pointee = true
            }
        }

        return assets
    }
}

extension Album: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            
            if let changeDetails = changeInstance.changeDetails(for: self.fetchResult) {
                let previousPhotosCount = self.fetchResult.count
                self.fetchResult = changeDetails.fetchResultAfterChanges
                self.updatedFetchResultsHandler(self)
                
                if changeDetails.hasIncrementalChanges == false
                    || changeDetails.hasMoves {
                    self.delegate?.didResetFetchResult()
                } else {
                    let removedIndexPaths = changeDetails.removedIndexes?.indexPaths(withSection: 0)
                    let insertedIndexPaths = changeDetails.insertedIndexes?.indexPaths(withSection: 0)
                    let changedIndexPaths = changeDetails.changedIndexes?.indexPaths(withSection: 0)
                    
                    if let lastIndex = removedIndexPaths?.last?.item, lastIndex >= previousPhotosCount {
                        self.delegate?.didResetFetchResult()
                    } else {
                        self.delegate?.didChange(removedIndexPaths: removedIndexPaths,
                                                 insertedIndexPaths: insertedIndexPaths,
                                                 changedIndexPaths: changedIndexPaths)
                    }
                }
            }
        }
    }
}


