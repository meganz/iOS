
import Photos
import UIKit

final class AlbumsTableViewDataSource: NSObject, UITableViewDataSource {
    private let albums: Albums
    private let imageManager = PHCachingImageManager.default()
    
    // MARK: - Initializer.
    
    init(albums: Albums) {
        self.albums = albums
    }

    // MARK: - Table view data source.
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       albums.numberOfAlbums()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlbumTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? AlbumTableViewCell else {
            fatalError("could not dequeue the AlbumTableViewCell cell")
        }
        
        cell.album = albums.album(at: indexPath.row)
        return cell
    }
}
