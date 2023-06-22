
import Photos
import UIKit

enum PhotoLibrarySelectionSource {
    case chat
    case other
}

enum PhotoAlbumItemsPerRowCount: Int {
    case chat = 3
    case other = 5
}

final class PhotoGridViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var sendBarButton: UIBarButtonItem?
    private var allBarButton: UIBarButtonItem?
    
    private lazy var diffableDataSource: PhotoGridViewDiffableDataSource? = {
        PhotoGridViewDiffableDataSource(
            collectionView: collectionView,
            selectedAssets: []
        ) { [weak self] asset, indexPath, cellSize, touchPoint in
            guard let self = self else { return }
            self.tapAsset(asset: asset, indexPath: indexPath, cellSize: cellSize, touchPoint: touchPoint)
        }
    }()
    private var delegate: PhotoGridViewDelegate?
    
    private let album: Album
    private let completionBlock: AlbumsTableViewController.CompletionBlock
    
    private let selectionActionType: AlbumsSelectionActionType
    private let selectionActionDisabledText: String
    private let source: PhotoLibrarySelectionSource
    
    // MARK: - Initializers.
    
    init(album: Album,
         selectionActionType: AlbumsSelectionActionType,
         selectionActionDisabledText: String,
         completionBlock: @escaping AlbumsTableViewController.CompletionBlock,
         source: PhotoLibrarySelectionSource) {
        self.album = album
        self.completionBlock = completionBlock
        self.selectionActionType = selectionActionType
        self.selectionActionDisabledText = selectionActionDisabledText
        self.source = source
        super.init(nibName: "PhotoGridViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = album.title
        collectionView?.register(PhotoGridViewCell.nib,
                                 forCellWithReuseIdentifier: PhotoGridViewCell.reuseIdentifier)
        collectionView.allowsMultipleSelection = true
        updateView()
        addToolbar()
        addRightCancelBarButtonItem()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBottomView()
        
        navigationController?.presentationController?.delegate = self
        album.delegate = self
        
        diffableDataSource?.load(assets: album.allAssets)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Hide toolbar in case of pop. Do not hide if it push
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setToolbarHidden(true, animated: false)
        }
        
        album.delegate = nil
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Private methods.
    
    private func showDetail(indexPath: IndexPath) {
        guard let selectedAssets = diffableDataSource?.selectedAssets  else {
            return
        }
        
        let photoCarousalViewController = PhotoCarouselViewController(album: album,
                                                                      selectedPhotoIndexPath: indexPath,
                                                                      selectedAssets: selectedAssets,
                                                                      selectionActionType: selectionActionType,
                                                                      selectionActionDisabledText: selectionActionDisabledText,
                                                                      delegate: self)
        navigationController?.pushViewController(photoCarousalViewController, animated: true)
    }
    
    private func updateBottomView() {
        let assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        sendBarButton?.title = assetsCount > 0 ? selectionActionType.localizedTextWithCount(assetsCount) : selectionActionDisabledText
        sendBarButton?.isEnabled = assetsCount > 0
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func updateView() {
        title = album.title
        
        diffableDataSource?.configureDataSource()
        
        delegate = PhotoGridViewDelegate(collectionView: collectionView) { [weak self] in
            guard let weakSelf = self else {
                return 1
            }
            
            var cellsPerRow = PhotoAlbumItemsPerRowCount.other.rawValue
            if weakSelf.source == .chat {
                cellsPerRow = PhotoAlbumItemsPerRowCount.chat.rawValue
            }
            
            if weakSelf.traitCollection.horizontalSizeClass == .regular &&
                    weakSelf.traitCollection.verticalSizeClass == .regular {
                cellsPerRow = PhotoAlbumItemsPerRowCount.other.rawValue
            }
            
            return cellsPerRow
        }
        
        delegate?.isMultiSelectionEnabled = { [weak self] isEnabled in
            self?.diffableDataSource?.isMultipleSelectionEnabled = isEnabled
        }
        
        delegate?.updateBottomView = { [weak self] in
            self?.updateBottomView()
        }
        
        collectionView.delegate = delegate
    }
    
    private func didSelect(asset: PHAsset, indexPath: IndexPath) {
        diffableDataSource?.didSelect(asset: asset)
    }
    
    private func tapAsset(asset: PHAsset, indexPath: IndexPath, cellSize: CGSize, touchPoint: CGPoint) {
        if source == .chat {
            if touchPoint.x >= (cellSize.width / 2.0)
                && touchPoint.y <= (cellSize.height / 2.0) {
                didSelect(asset: asset, indexPath: indexPath)
            } else {
                showDetail(indexPath: indexPath)
            }
        } else {
            didSelect(asset: asset, indexPath: indexPath)
        }
        
        updateBottomView()
    }
    
    private func addToolbar() {
        sendBarButton = UIBarButtonItem(title: selectionActionDisabledText, style: .plain, target: self, action: #selector(sendButtonTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        if album.subType != .smartAlbumUserLibrary {
            allBarButton = UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(allButtonTapped))
            toolbarItems = [allBarButton!, spacer, sendBarButton!]
        } else {
            toolbarItems = [spacer, sendBarButton!]
        }
    }
    
    @objc private func allButtonTapped() {
        let assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        let selectedAssets = assetsCount == collectionView.numberOfItems(inSection: 0) ? [] : album.allAssets
    
        diffableDataSource?.selectedAssets = selectedAssets
        diffableDataSource?.reload(assets: album.allAssets)
        updateBottomView()
    }
}

extension PhotoGridViewController: PhotoCarouselViewControllerDelegate {
    func selected(assets: [PHAsset]) {
        diffableDataSource?.selectedAssets = assets
        diffableDataSource?.load(assets: album.allAssets)
        updateBottomView()
    }
    
    @objc func sendButtonTapped() {
        guard let selectedAssets = diffableDataSource?.selectedAssets, !selectedAssets.isEmpty else {
            return
        }
        
        dismiss(animated: true) {
            self.completionBlock(selectedAssets)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PhotoGridViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return diffableDataSource?.selectedAssets.count ?? 0 == 0
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard let barButton = navigationItem.rightBarButtonItem else { return }
        let assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        if assetsCount > 0 {
            let discardChangesActionSheet = UIAlertController().discardChanges(fromBarButton: barButton, withConfirmAction: {
                self.dismiss(animated: true, completion: nil)
            })
            present(discardChangesActionSheet, animated: true, completion: nil)
        }
    }
}

extension PhotoGridViewController: AlbumDelegate {
    func didResetFetchResult() {
        diffableDataSource?.load(assets: album.allAssets)
    }
    
    func didChange(removedIndexPaths: [IndexPath]?,
                   insertedIndexPaths: [IndexPath]?,
                   changedIndexPaths: [IndexPath]?) {
        diffableDataSource?.load(assets: album.allAssets)
        updateBottomView()
    }
}
