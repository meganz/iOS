
import UIKit
import Photos

class AlbumsTableViewController: UITableViewController {
    var albumsDataSource: AlbumsTableViewDataSource?
    var albumsDelegate: AlbumsTableViewDelegate?
    let albums = Albums()
    let completionBlock: AlbumsTableViewController.CompletionBlock
    
    typealias CompletionBlock = ([PHAsset]) -> Void
    
    // MARK:- Initializers.
    
    @objc init(completionBlock: @escaping ([PHAsset]) -> Void) {
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- View controller Lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        addLeftCancelBarButtonItem()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if albums.numberOfAlbums() == 0 {
            showNoPhotosOrVideos()
        }
    }
    
    // MARK:- Orientation method.
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK:- Private methods.
    
    private func showDetail(album: Album) {
        let gridViewController = PhotoGridViewController(album: album, completionBlock: completionBlock)
        navigationController?.pushViewController(gridViewController, animated: true)
    }
    
    private func showNoPhotosOrVideos() {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "No Photos or Videos".localized()
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}


