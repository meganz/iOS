import Foundation

final class MiniPlayerDataSource: NSObject, MiniPlayerSource {
    var tracks: [AudioPlayerItem?]?
    
    init(currentTrack: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool = false) {
        if let queue = queue {
            tracks = loopMode ? queue + [currentTrack] : queue
        } else {
            tracks = [currentTrack]
        }
    }
    
    func item(at indexPath: IndexPath) -> AudioPlayerItem? {
        tracks?[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tracks?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cell(at: indexPath, in: collectionView)
    }
}
