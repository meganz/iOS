
import UIKit
import Photos

class AlbumsTableViewController: UITableViewController {
    var albumsDataSource: AlbumsTableViewDataSource?
    var albumsDelegate: AlbumsTableViewDelegate?
    let albums = Albums()
    let completionBlock: AlbumsTableViewController.CompletionBlock
    
    typealias CompletionBlock = ([PHAsset]) -> Void
    
    @objc init(completionBlock: @escaping ([PHAsset]) -> Void) {
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Need to localize
        title = "Albums".localized()
        tableView.register(UINib(nibName: "AlbumTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "AlbumTableViewCell")
        tableView.rowHeight = 110.0
        
        albumsDataSource = AlbumsTableViewDataSource(albums: albums)
        tableView.dataSource = albumsDataSource
        
        albumsDelegate = AlbumsTableViewDelegate { [weak self] album in
            self?.showDetail(album: album)
        }
        tableView.delegate = albumsDelegate
        
        self.navigationController?.delegate = self
        addLeftCancelBarButtonItem()
    }
    
    func showDetail(album: Album) {
        navigationController?.pushViewController(PhotoGridViewController(album: album, completionBlock: completionBlock),
                                                 animated: true)

    }
}

extension AlbumsTableViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return .portrait
    }
}


