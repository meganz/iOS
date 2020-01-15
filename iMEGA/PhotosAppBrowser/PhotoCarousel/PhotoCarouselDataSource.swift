
import UIKit

class PhotoCarouselDataSource: PhotoGridViewDataSource {
    override func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCarouselCell.reuseIdentifier,
                                                      for: indexPath) as! PhotoCarouselCell
        
        let asset = album.asset(atIndex: indexPath.item)
        cell.asset = asset
        cell.selectedIndex = selectedAssets.firstIndex(of: asset)
        cell.durationString = (asset.mediaType == .video) ? asset.duration.timeDisplayString : nil
        return cell
    }
    
    override func updateCollectionCell(atIndexPath indexPath: IndexPath, selectedIndex: Int?) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCarouselCell
        cell.selectedIndex = selectedIndex
    }
}
