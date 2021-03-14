import Foundation

protocol AudioPlaylistDelegate: class {
    func didSelect(item: AudioPlayerItem)
    func didDeselect(item: AudioPlayerItem)
}

final class AudioPlaylistIndexedDelegate: NSObject, UITableViewDelegate {
    private weak var delegate: AudioPlaylistDelegate?
    private let traitCollection: UITraitCollection
    
    init(delegate: AudioPlaylistDelegate, traitCollection: UITraitCollection) {
        self.delegate = delegate
        self.traitCollection = traitCollection
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemTableViewCell,
              let item = cell.item else {
            return
        }
        
        cell.setSelected(true, animated: true)
        
        delegate?.didSelect(item: item)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistItemTableViewCell,
              let item = cell.item else {
            return
        }
        
        cell.setSelected(false, animated: true)
        
        delegate?.didDeselect(item: item)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "PlaylistHeaderFooterView") as? PlaylistHeaderFooterView else { return nil}
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        header.configure(title: section == 0 ?
            NSLocalizedString("Playing", comment: "Section header of Audio Player playlist that contains playing track") :
            NSLocalizedString("Next", comment: "Section header of Audio Player playlist that contains next tracks"))

        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        48.0
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
}
