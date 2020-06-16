
import UIKit
import Photos

final class Album {
    let title: String
    private let fetchResult: PHFetchResult<PHAsset>
    
    // MARK:- Initializer.

    init(title: String, fetchResult: PHFetchResult<PHAsset>) {
        self.title = title
        self.fetchResult = fetchResult
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



