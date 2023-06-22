import Photos
import UIKit

class PhotoGridViewBaseDataSource: NSObject {
    weak var collectionView: UICollectionView?
    var selectedAssets: [PHAsset]
    var tempSelectedAssets: [PHAsset]?
    typealias SelectionHandler = (PHAsset, IndexPath, CGSize, CGPoint) -> Void
    let selectionHandler: SelectionHandler
    var isMultipleSelectionEnabled: Bool = false {
        didSet {
            guard let collectionView = collectionView else { return }
            if isMultipleSelectionEnabled {
                tempSelectedAssets = selectedAssets
            } else {
                selectedAssets = tempSelectedAssets ?? []
                tempSelectedAssets = nil
                if let selectedItems = collectionView.indexPathsForSelectedItems {
                    selectedItems.forEach { collectionView.deselectItem(at: $0, animated: false) }
                }
            }
        }
    }

    // MARK: - Initializer.

    init(collectionView: UICollectionView,
         selectedAssets: [PHAsset],
         selectionHandler: @escaping SelectionHandler) {
        self.collectionView = collectionView
        self.selectedAssets = selectedAssets
        self.selectionHandler = selectionHandler
    }
    
    // MARK: - methods.
    
    func handlePanSelection (isSelected: Bool, asset: PHAsset) -> Int? {
        if isSelected {
            if selectedAssets.contains(asset) {
                if let index = tempSelectedAssets?.firstIndex(of: asset) {
                    tempSelectedAssets?.remove(at: index)
                    updateSelectedAssetsIndex(fromIndex: index, selectedAssets: tempSelectedAssets ?? [])
                }
            } else {
                tempSelectedAssets?.append(asset)
            }
        } else if let index = tempSelectedAssets?.firstIndex(of: asset) {
            if !selectedAssets.contains(asset) {
                tempSelectedAssets?.remove(at: index)
                updateSelectedAssetsIndex(fromIndex: index, selectedAssets: tempSelectedAssets ?? [])
            }
        }

        return tempSelectedAssets?.firstIndex(of: asset)
    }
    
    func updateSelectedAssetsIndex(fromIndex index: Int, selectedAssets: [PHAsset]) {
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
    
    func configureCell(cell: PhotoGridViewCell, indexPath: IndexPath, asset: PHAsset) {
        cell.asset = asset
        cell.selectedIndex = selectedAssets.firstIndex(of: asset)
        
        cell.tapHandler = { [weak self] instance, size, point in
            guard let self = self, let selectedAsset = instance.asset else { return }
            self.selectionHandler(selectedAsset, indexPath, size, point)
        }
        
        cell.panSelectionHandler = { [weak self] isSelected, asset in
            guard let self = self, self.isMultipleSelectionEnabled else { return self?.selectedAssets.firstIndex(of: asset) }
            return self.handlePanSelection(isSelected: isSelected, asset: asset)
        }
        
        cell.durationString = (asset.mediaType == .video) ? asset.duration.timeString : nil
    }
}
