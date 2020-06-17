
import UIKit
import Photos

final class AlbumsTableViewController: UITableViewController {
    private var albumsDataSource: AlbumsTableViewDataSource?
    private var albumsDelegate: AlbumsTableViewDelegate?
    private let albums = Albums()
    private let selectionActionText: String
    private let selectionActionDisabledText: String
    private let completionBlock: AlbumsTableViewController.CompletionBlock
    
    typealias CompletionBlock = ([PHAsset]) -> Void
    
    // MARK:- Initializers.
    
    @objc init(selectionActionText: String,
               selectionActionDisabledText: String,
               completionBlock: @escaping ([PHAsset]) -> Void) {
        self.selectionActionText = selectionActionText
        self.selectionActionDisabledText = selectionActionDisabledText
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- View controller Lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("Albums", "Used in Photos app browser album listing screen.")
        tableView.register(AlbumTableViewCell.nib,
                           forCellReuseIdentifier: AlbumTableViewCell.reuseIdentifier)
        tableView.rowHeight = 110.0
        
        albumsDataSource = AlbumsTableViewDataSource(albums: albums)
        tableView.dataSource = albumsDataSource
        
        albumsDelegate = AlbumsTableViewDelegate { [weak self] album in
            self?.showDetail(album: album)
        }
        tableView.delegate = albumsDelegate
        
        addRightCancelBarButtonItem()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if albums.numberOfAlbums() == 0 {
            showNoPhotosOrVideos()
        }
        
        navigationController?.navigationBar.isTranslucent = false
    }
    
    // MARK:- Orientation method.
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK:- Private methods.
    
    private func showDetail(album: Album) {
        let gridViewController = PhotoGridViewController(album: album,
                                                         selectionActionText: selectionActionText,
                                                         selectionActionDisabledText: selectionActionDisabledText,
                                                         completionBlock: completionBlock)
        navigationController?.pushViewController(gridViewController, animated: true)
    }
    
    private func showNoPhotosOrVideos() {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = AMLocalizedString("No Photos or Videos", "Used in Photos app browser. Shown when there are no photos or videos in the Photos app.")
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}


