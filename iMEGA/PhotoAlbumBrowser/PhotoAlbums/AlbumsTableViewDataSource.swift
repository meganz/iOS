
import UIKit
import Photos

class AlbumsTableViewDataSource: NSObject, UITableViewDataSource {
    let albums: Albums
    let imageManager = PHCachingImageManager.default()
    
    init(albums: Albums) {
        self.albums = albums
    }

    // MARK :- Table view data source.
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.numberOfAlbums()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumTableViewCell", for: indexPath) as! AlbumTableViewCell
        
        cell.album = albums.album(at: indexPath.row)
        
        return cell
    }
}

