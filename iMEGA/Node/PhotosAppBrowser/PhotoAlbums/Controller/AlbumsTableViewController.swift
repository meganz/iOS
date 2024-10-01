import MEGAL10n
import MEGAPermissions
import MEGAUIKit
import Photos
import UIKit

final class AlbumsTableViewController: UITableViewController {
    private var albumsDataSource: AlbumsTableViewDataSource?
    private var albumsDelegate: AlbumsTableViewDelegate?
    private let albums: Albums
    private let selectionActionType: AlbumsSelectionActionType
    private let selectionActionDisabledText: String
    private let completionBlock: AlbumsTableViewController.CompletionBlock
    var source: PhotoLibrarySelectionSource = .other
    
    private let noPhotosOrVideosLabel = UILabel()
    
    typealias CompletionBlock = ([PHAsset]) -> Void
    
    // MARK: - Initializers.
    
    @objc init(
        selectionActionType: AlbumsSelectionActionType,
        selectionActionDisabledText: String,
        completionBlock: @escaping ([PHAsset]) -> Void
    ) {
        self.selectionActionType = selectionActionType
        self.selectionActionDisabledText = selectionActionDisabledText
        self.completionBlock = completionBlock
        self.albums = .init(
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            photoLibraryRegisterer: PHPhotoLibrary.shared()
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller Lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Localizable.albums
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
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.albums)
        
        configureNoPhotosOrVideosLabel()
        
        albums.loadAlbums { [weak self] in
            guard let self else { return }
            
            tableView.reloadData()
            
            noPhotosOrVideosLabel.isHidden = !albums.isEmpty
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        albums.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        albums.delegate = nil
    }
    
    // MARK: - Private methods.
    
    private func showDetail(album: Album) {
        let gridViewController = PhotoGridViewController(album: album,
                                                         selectionActionType: selectionActionType,
                                                         selectionActionDisabledText: selectionActionDisabledText,
                                                         completionBlock: completionBlock,
                                                         source: source)
        navigationController?.pushViewController(gridViewController, animated: true)
    }
    
    private func configureNoPhotosOrVideosLabel() {
        noPhotosOrVideosLabel.textAlignment = .center
        noPhotosOrVideosLabel.font = UIFont.preferredFont(forTextStyle: .body)
        noPhotosOrVideosLabel.text = Strings.Localizable.noPhotosOrVideos
        noPhotosOrVideosLabel.isHidden = true
        view.addSubview(noPhotosOrVideosLabel)
        
        noPhotosOrVideosLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noPhotosOrVideosLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noPhotosOrVideosLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension AlbumsTableViewController: AlbumsDelegate {
    func albumAdded(_ album: Album, atIndex index: Int) {
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: index, section: 0)],
                             with: .automatic)
        tableView.endUpdates()
    }
    
    func albumRemoved(_ album: Album, atIndex index: Int) {
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)],
                             with: .automatic)
        tableView.endUpdates()
    }
    
    func albumModified(_ album: Album, atIndex index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)],
                             with: .automatic)
    }
    
    func albumsReplaced() {
        tableView.reloadData()
    }
}
