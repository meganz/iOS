
import UIKit

final class AlbumsTableViewDelegate: NSObject, UITableViewDelegate {
    private let tapHandler: (Album) -> Void
    
    // MARK:- Initializer.

    init(tapHandler: @escaping (Album) -> Void) {
        self.tapHandler = tapHandler
    }
    
    // MARK:- UITableViewDelegate methods.
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? AlbumTableViewCell else { return }
        tableViewCell.displayPreviewImages()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? AlbumTableViewCell else { return }
        tableViewCell.cancelPreviewImagesLoading()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) as? AlbumTableViewCell,
            let selectedAlbum = cell.album else {
                return
        }
        
        tapHandler(selectedAlbum)
    }
}
