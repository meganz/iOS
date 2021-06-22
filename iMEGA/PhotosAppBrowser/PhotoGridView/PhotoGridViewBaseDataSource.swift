import UIKit
import Photos

class PhotoGridViewBaseDataSource: NSObject {
    weak var collectionView: UICollectionView?
    var selectedAssets: [PHAsset]
    typealias SelectionHandler = (PHAsset, IndexPath, CGSize, CGPoint) -> Void
    let selectionHandler: SelectionHandler
    var isMultipleSelectionEnabled: Bool = false

    // MARK:- Initializer.

    init(collectionView: UICollectionView,
         selectedAssets: [PHAsset],
         selectionHandler: @escaping SelectionHandler) {
        self.collectionView = collectionView
        self.selectedAssets = selectedAssets
        self.selectionHandler = selectionHandler
    }
    
    // MARK:- methods.
    
    func handlePanSelection (isSelected: Bool, asset: PHAsset) -> Int? {
        guard self.isMultipleSelectionEnabled else {
            return nil
        }
        
        if isSelected && !selectedAssets.contains(asset) {
            selectedAssets.append(asset)
        } else if !isSelected && selectedAssets.contains(asset) {
            if let index = selectedAssets.firstIndex(of: asset) {
                selectedAssets.remove(at: index)
                updateSelectedAssetsIndex(fromIndex: index)
            }
        }
        
        return selectedAssets.firstIndex(of: asset)
    }
    
    func updateSelectedAssetsIndex(fromIndex index: Int) {
        let totalCount = selectedAssets.count
        (index..<totalCount).forEach { index in
            let toUpdatAsset = selectedAssets[index]
            if let visibleCells = collectionView?.visibleCells as? [PhotoGridViewCell] {
                visibleCells.forEach { cell in
                    if let asset = cell.asset,
                        asset == toUpdatAsset {
                        cell.selectedIndex = index
                    }
                }
            }
        }
    }
}
