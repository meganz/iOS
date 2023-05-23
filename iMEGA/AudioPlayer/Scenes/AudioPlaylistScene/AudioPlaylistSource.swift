import Foundation

protocol AudioPlaylistSource: UITableViewDataSource {
    func item(at indexPath: IndexPath) -> AudioPlayerItem?
    func indexPathsOf(item: AudioPlayerItem) -> [IndexPath]
}

extension AudioPlaylistSource  {
    func cell(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath) as? PlaylistItemTableViewCell else { return UITableViewCell() }
        
        cell.setSelectedBackgroundView(withColor: .clear)
        cell.configure(item: item(at: indexPath))
        
        return cell
    }
}
