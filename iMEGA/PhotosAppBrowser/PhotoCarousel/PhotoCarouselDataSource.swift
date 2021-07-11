
import UIKit

final class PhotoCarouselDataSource: PhotoGridViewDataSource {
    override func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCarouselCell.reuseIdentifier,
                                                            for: indexPath) as? PhotoCarouselCell else {
                                                                fatalError("Could not dequeue the PhotoCarouselCell cell")
        }
        
        let asset = album.asset(atIndex: indexPath.item)
        cell.asset = asset
        cell.selectedIndex = selectedAssets.firstIndex(of: asset)
        cell.durationString = (asset.mediaType == .video) ? asset.duration.timeDisplayString() : nil
        return cell
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
