import Foundation

protocol MiniPlayerSource: UICollectionViewDataSource {
    func item(at indexPath: IndexPath) -> AudioPlayerItem?
    func indexPath(for item: AudioPlayerItem) -> IndexPath?
}

extension MiniPlayerSource {
    func cell(at indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "miniTrackCell", for: indexPath) as? MiniPlayerItemCollectionViewCell else { return UICollectionViewCell() }
        
        cell.configure(item: item(at: indexPath))
        
        return cell
    }
}
