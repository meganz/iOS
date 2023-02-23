
import UIKit
import Photos

final class PhotoCarouselDataSource: PhotoGridViewDataSource {
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCarouselCell.reuseIdentifier,
                                                            for: indexPath) as? PhotoCarouselCell else {
            fatalError("Could not dequeue the PhotoCarouselCell cell")
        }
        
        let asset = album.asset(atIndex: indexPath.item)
        configCell(cell, by: asset)
        return cell
    }
    
    private func configCell(_ cell: PhotoCarouselCell, by asset: PHAsset) {
        cell.asset = asset
        cell.selectedIndex = selectedAssets.firstIndex(of: asset)
        cell.durationString = (asset.mediaType == .video) ? asset.duration.timeString : nil
    }
    
    override func updateCollectionCell(atIndexPath indexPath: IndexPath, selectedIndex: Int?) {
        guard let cell = collectionView?.cellForItem(at: indexPath) as? PhotoCarouselCell else { return }
        cell.selectedIndex = selectedIndex
    }
    
    func asset(atIndexPath indexPath: IndexPath) -> PHAsset? {
        if let cell = collectionView?.cellForItem(at: indexPath) as? PhotoCarouselCell {
            return cell.asset
        }
        
        return nil
    }
}
