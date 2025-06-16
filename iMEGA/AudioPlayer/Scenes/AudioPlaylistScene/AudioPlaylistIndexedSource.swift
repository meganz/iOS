import Foundation

protocol AudioPlaylistSourceDelegate: AnyObject {
    func move(item: AudioPlayerItem, position: IndexPath, direction: MovementDirection)
}

final class AudioPlaylistIndexedSource: NSObject, AudioPlaylistSource, UITableViewDataSource {
    private var indexedTracks: [[AudioPlayerItem?]?]
    private weak var delegate: (any AudioPlaylistSourceDelegate)?
    
    init(currentTrack: AudioPlayerItem?, queue: [AudioPlayerItem]?, delegate: some AudioPlaylistSourceDelegate) {
        self.indexedTracks = [[currentTrack], queue]
        self.delegate = delegate
    }
    
    func item(at indexPath: IndexPath) -> AudioPlayerItem? {
        indexedTracks[indexPath.section]?[indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        indexedTracks.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        indexedTracks[section]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell(at: indexPath, in: tableView)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section != 0 else { return false }
        return tableView.indexPathsForSelectedRows?.isEmpty ?? true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section != 0
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if destinationIndexPath.section != 0, sourceIndexPath != destinationIndexPath {
            guard let itemToMove = item(at: sourceIndexPath) else { return }
            
            indexedTracks[sourceIndexPath.section]?.remove(at: sourceIndexPath.row)
            indexedTracks[destinationIndexPath.section]?.insert(itemToMove, at: destinationIndexPath.row)
            
            delegate?.move(item: itemToMove, position: IndexPath(row: destinationIndexPath.row + 1, section: 0), direction: sourceIndexPath > destinationIndexPath ? .up : .down)
        }
    }
    
    func indexPathsOf(item: AudioPlayerItem) -> [IndexPath] {
        indexedTracks.compactMap { list in
            guard let section = indexedTracks.firstIndex(of: list) else { return nil }
            return list?.filter({ $0 == item }).compactMap {
                guard let row = list?.firstIndex(of: $0) else { return nil }
                return IndexPath(row: row, section: section)
            }
        }.reduce([], +)
        .removeDuplicatesWhileKeepingTheOriginalOrder()
    }
}
