import Foundation
import MEGADesignToken
import MEGAL10n

protocol AudioPlaylistDelegate: AnyObject {
    func didSelect(item: AudioPlayerItem)
    func didDeselect(item: AudioPlayerItem)
    func draggWillBegin()
    func draggDidEnd()
}

final class AudioPlaylistIndexedDelegate: NSObject, UITableViewDelegate, UITableViewDragDelegate {
    private weak var delegate: (any AudioPlaylistDelegate)?
    private let traitCollection: UITraitCollection
    
    init(delegate: some AudioPlaylistDelegate, traitCollection: UITraitCollection) {
        self.delegate = delegate
        self.traitCollection = traitCollection
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        indexPath.section != 0 ? indexPath : nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != 0, let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemTableViewCell,
              let item = cell.item else {
            return
        }
        
        cell.setSelected(true, animated: true)
        
        delegate?.didSelect(item: item)
        refreshReorderHandles(in: tableView)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard indexPath.section != 0, let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemTableViewCell,
              let item = cell.item else {
            return
        }
        
        cell.setSelected(false, animated: true)
        
        delegate?.didDeselect(item: item)
        refreshReorderHandles(in: tableView)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "PlaylistHeaderFooterView") as? PlaylistHeaderFooterView else { return nil}
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = TokenColors.Background.page
        header.configure(title: section == 0 ? Strings.Localizable.playing : Strings.Localizable.Media.Audio.Playlist.Section.Next.title)

        return header
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        sourceIndexPath.section != proposedDestinationIndexPath.section ? sourceIndexPath : proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        indexPath.section != 0
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: any UIDragSession) {
        delegate?.draggWillBegin()
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: any UIDragSession) {
        delegate?.draggDidEnd()
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        []
    }
    
    /// Refreshes the visibility of the system reorder control (“≡”) on visible cells. By walking only the currently visible rows and toggling each cell’s
    /// `showsReorderControl` flag based on whether any rows are selected, we avoid reloading the entire table.
    private func refreshReorderHandles(in tableView: UITableView) {
        let anySelected = (tableView.indexPathsForSelectedRows?.isNotEmpty ?? false)
        
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            let isRowReorderable = indexPath.section != 0
            cell.showsReorderControl = (isRowReorderable && !anySelected)
        }
    }
}
