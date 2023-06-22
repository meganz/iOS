
import Photos
import UIKit

class PhotoGridViewDataSource: PhotoGridViewBaseDataSource {
    var album: Album

    // MARK: - Initializer.

    init(album: Album,
         collectionView: UICollectionView,
         selectedAssets: [PHAsset],
         selectionHandler: @escaping SelectionHandler) {
        self.album = album
        super.init(collectionView: collectionView, selectedAssets: selectedAssets, selectionHandler: selectionHandler)
    }
    
    // MARK: - Interface methods.

    func didSelect(asset: PHAsset, atIndexPath indexPath: IndexPath) {
        if let index = selectedAssets.firstIndex(of: asset) {
           remove(asset: asset, atIndex: index, selectedIndexPath: indexPath)
        } else {
            add(asset: asset, selectedIndexPath: indexPath)
        }
    }
    
    func updateCollectionCell(atIndexPath indexPath: IndexPath, selectedIndex: Int?) {
        guard let collectionCell = collectionView?.cellForItem(at: indexPath) as? PhotoGridViewCell else { return }
        collectionCell.selectedIndex = selectedIndex
    }
    
    // MARK: - Private methods.
    
    private func add(asset: PHAsset, selectedIndexPath: IndexPath) {
        updateCollectionCell(atIndexPath: selectedIndexPath, selectedIndex: selectedAssets.count)
        selectedAssets.append(asset)
    }
    
    private func remove(asset: PHAsset, atIndex index: Int, selectedIndexPath: IndexPath) {
        selectedAssets.remove(at: index)
        updateCollectionCell(atIndexPath: selectedIndexPath, selectedIndex: nil)
        updateSelectedAssetsIndex(fromIndex: index, selectedAssets: selectedAssets)
    }
}

// MARK: - UICollectionViewDataSource.

extension PhotoGridViewDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       album.assetCount()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridViewCell.reuseIdentifier,
                                                            for: indexPath) as? PhotoGridViewCell else {
                                                                fatalError("Could not dequeue cell PhotoGridViewCell")
                                                                
        }
        
        configureCell(cell: cell, indexPath: indexPath, asset: album.asset(atIndex: indexPath.item))
        return cell
    }
}
