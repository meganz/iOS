
import UIKit
import Photos

final class PhotoGridViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var sendBarButton: UIBarButtonItem?
    private var allBarButton: UIBarButtonItem?
    
    private var dataSource: PhotoGridViewDataSource?
    @available(iOS 13.0, *)
    private lazy var diffableDataSource: PhotoGridViewDiffableDataSource? = {
        PhotoGridViewDiffableDataSource(
            collectionView: collectionView,
            selectedAssets: []
        ) { [weak self] asset, indexPath, cellSize, touchPoint in
            guard let self = self else { return }
            self.didSelect(asset: asset, indexPath: indexPath, cellSize: cellSize, touchPoint: touchPoint)
        }
    }()
    private var delegate: PhotoGridViewDelegate?
    
    private let album: Album
    private let completionBlock: AlbumsTableViewController.CompletionBlock
    
    private let selectionActionText: String
    private let selectionActionDisabledText: String
    
    // MARK:- Initializers.
    
    init(album: Album,
         selectionActionText: String,
         selectionActionDisabledText: String,
         completionBlock: @escaping AlbumsTableViewController.CompletionBlock) {
        self.album = album
        self.completionBlock = completionBlock
        self.selectionActionText = selectionActionText
        self.selectionActionDisabledText = selectionActionDisabledText
        super.init(nibName: "PhotoGridViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- View controller lifecycle methods.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = album.title
        collectionView?.register(PhotoGridViewCell.nib,
                                 forCellWithReuseIdentifier: PhotoGridViewCell.reuseIdentifier)
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
        
        if #available(iOS 13.0, *) {
            diffableDataSource?.load(assets: album.allAssets)
        }
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
    
    // MARK:- Private methods.
    
    private func showDetail(indexPath: IndexPath) {
        let selectedAssets: [PHAsset]?
        if #available(iOS 13.0, *) {
            selectedAssets = diffableDataSource?.selectedAssets
        } else {
            selectedAssets = dataSource?.selectedAssets
        }
        
        guard let selectedAssets = selectedAssets  else {
            return
        }
        
        let photoCarousalViewController = PhotoCarouselViewController(album: album,
                                                                      selectedPhotoIndexPath: indexPath,
                                                                      selectedAssets: selectedAssets,
                                                                      selectionActionText: selectionActionText,
                                                                      selectionActionDisabledText: selectionActionDisabledText,
                                                                      delegate: self)
        navigationController?.pushViewController(photoCarousalViewController, animated: true)
    }
    
    private func updateBottomView() {
        let assetsCount: Int
        if #available(iOS 13.0, *) {
            assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        } else {
            assetsCount = dataSource?.selectedAssets.count ?? 0
        }
        
        sendBarButton?.title = assetsCount > 0 ? String(format: selectionActionText, assetsCount) : selectionActionDisabledText
        sendBarButton?.isEnabled = assetsCount > 0
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func updateView() {
        title = album.title
        
        if #available(iOS 13.0, *) {
            diffableDataSource?.configureDataSource()
        } else {
            dataSource = PhotoGridViewDataSource(
                album: album,
                collectionView: collectionView,
                selectedAssets: []
            ) { [weak self] asset, indexPath, cellSize, touchPoint in
                guard let self = self else { return }
                self.didSelect(asset: asset, indexPath: indexPath, cellSize: cellSize, touchPoint: touchPoint)
            }
            collectionView.dataSource = dataSource
        }
        
        delegate = PhotoGridViewDelegate(collectionView: collectionView) { [weak self] in
            guard let weakSelf = self else {
                return 1
            }
            
            var cellsPerRow = 3
            
            switch (weakSelf.traitCollection.horizontalSizeClass,
                    weakSelf.traitCollection.verticalSizeClass) {
            case (.regular, .regular):
                cellsPerRow = 5
            default:
                cellsPerRow = 3
            }
            
            return cellsPerRow
        }
        
        collectionView.delegate = delegate
    }
    
    private func didSelect(asset: PHAsset, indexPath: IndexPath, cellSize: CGSize, touchPoint: CGPoint) {
        if touchPoint.x >= (cellSize.width / 2.0)
            && touchPoint.y <= (cellSize.height / 2.0) {
            if #available(iOS 13.0, *) {
                diffableDataSource?.didSelect(asset: asset)
            } else {
                dataSource?.didSelect(asset: asset, atIndexPath: indexPath)
            }
        } else {
            showDetail(indexPath: indexPath)
        }
        
        updateBottomView()
    }
    
    private func addToolbar() {
        sendBarButton = UIBarButtonItem(title: selectionActionDisabledText, style: .plain, target: self, action: #selector(sendButtonTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        if album.subType != .smartAlbumUserLibrary {
            allBarButton = UIBarButtonItem(image: UIImage(named: "selectAll"), style: .plain, target: self, action: #selector(allButtonTapped))
            toolbarItems = [allBarButton!, spacer, sendBarButton!]
        } else {
            toolbarItems = [spacer, sendBarButton!]
        }
    }
    
    @objc private func allButtonTapped() {
        let assetsCount: Int
        if #available(iOS 13.0, *) {
            assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        } else {
            assetsCount = dataSource?.selectedAssets.count ?? 0
        }
        
        let selectedAssets = assetsCount == collectionView.numberOfItems(inSection: 0) ? [] : album.allAssets
        
        if #available(iOS 13.0, *) {
            diffableDataSource?.selectedAssets = selectedAssets
            diffableDataSource?.reload(assets: album.allAssets)
        } else {
            dataSource?.selectedAssets = selectedAssets
            collectionView.reloadData()
        }
        updateBottomView()
    }
}

extension PhotoGridViewController: PhotoCarouselViewControllerDelegate {
    func selected(assets: [PHAsset]) {
        if #available(iOS 13.0, *) {
            diffableDataSource?.selectedAssets = assets
            diffableDataSource?.load(assets: album.allAssets)
        } else {
            dataSource?.selectedAssets = assets
            collectionView.reloadData()
        }
        updateBottomView()
    }
    
    @objc func sendButtonTapped() {
        let selectedAssets: [PHAsset]
        if #available(iOS 13.0, *) {
            selectedAssets = diffableDataSource?.selectedAssets ?? []
        } else {
            selectedAssets = dataSource?.selectedAssets ?? []
        }
        
        guard !selectedAssets.isEmpty else {
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
        let assetsCount: Int
        
        if #available(iOS 13.0, *) {
            assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        } else {
            assetsCount = dataSource?.selectedAssets.count ?? 0
        }
        
        return assetsCount == 0
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard let barButton = navigationItem.rightBarButtonItem else { return }
        let assetsCount: Int
        
        if #available(iOS 13.0, *) {
            assetsCount = diffableDataSource?.selectedAssets.count ?? 0
        } else {
            assetsCount = dataSource?.selectedAssets.count ?? 0
        }
        
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
        if #available(iOS 13.0, *) {
            diffableDataSource?.load(assets: album.allAssets)
        } else {
            collectionView.reloadData()
        }
    }
    
    func didChange(removedIndexPaths: [IndexPath]?,
                   insertedIndexPaths: [IndexPath]?,
                   changedIndexPaths: [IndexPath]?) {
        if #available(iOS 13.0, *) {
            diffableDataSource?.load(assets: album.allAssets)
            updateBottomView()
            return
        } else {
            if let removedIndexPaths = removedIndexPaths,
                  let changedIndexPaths = changedIndexPaths,
                  !Set(changedIndexPaths).intersection(removedIndexPaths).isEmpty {
                collectionView.reloadData()
                return
            }
            
            if let lastIndex = removedIndexPaths?.last?.item, lastIndex >= album.assetCount() {
                collectionView.reloadData()
                return
            }
            
            collectionView.performBatchUpdates({
                if let removedIndexPaths = removedIndexPaths {
                    let selectedIndexPathsToBeDeleted = removeSelectedAssets(forIndexPaths: removedIndexPaths)
                    let selectedIndexPathsToBeReloaded = visibleSelectedAssetsIndexPaths(ignoreIndexPaths: selectedIndexPathsToBeDeleted)
                    collectionView.reloadItems(at:selectedIndexPathsToBeReloaded)
                    collectionView.deleteItems(at: removedIndexPaths)
                }
                
                if let insertedIndexPaths = insertedIndexPaths {
                    collectionView.insertItems(at: insertedIndexPaths)
                }
                
                if let changedIndexPaths = changedIndexPaths {
                    collectionView.reloadItems(at: changedIndexPaths)
                }
            }, completion: nil)
        }
    }
    
    private func removeSelectedAssets(forIndexPaths indexPaths: [IndexPath]) -> [IndexPath] {
        var deletedIndexPaths: [IndexPath] = []
        indexPaths.forEach { indexPath in
            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoGridViewCell,
                let asset = cell.asset,
                let dataSource = dataSource,
                let index = dataSource.selectedAssets.firstIndex(of: asset) {
                dataSource.selectedAssets.remove(at: index)
                deletedIndexPaths.append(indexPath)
            }
        }
        return deletedIndexPaths
    }
    
    private func visibleSelectedAssetsIndexPaths(ignoreIndexPaths indexPaths: [IndexPath]) -> [IndexPath] {
        return collectionView.visibleCells.compactMap { cell in
            if let cell = cell as? PhotoGridViewCell,
                cell.selectedIndex != nil,
                let cellIndexPath = collectionView.indexPath(for: cell),
                !indexPaths.contains(cellIndexPath) {
                return cellIndexPath
            }
            
            return nil
        }
    }
}
