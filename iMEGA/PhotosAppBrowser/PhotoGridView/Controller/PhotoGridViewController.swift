
import UIKit
import Photos

final class PhotoGridViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var sendBarButton: UIBarButtonItem?
    
    private var dataSource: PhotoGridViewDataSource?
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Hide toolbar in case of pop. Do not hide if it push
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setToolbarHidden(true, animated: false)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK:- Orientation method.
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
       .portrait
    }
    
    // MARK:- Private methods.
    
    private func showDetail(indexPath: IndexPath) {
        guard let selectedAssets = dataSource?.selectedAssets else {
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
        if let assetsCount = dataSource?.selectedAssets.count,
            (assetsCount > 0) {
            sendBarButton?.title = String(format: selectionActionText, assetsCount)
        }
        
        if navigationController?.topViewController == self {
            navigationController?.setToolbarHidden((dataSource?.selectedAssets.count ?? 0) == 0,
                                                   animated: true)
        }
    }
    
    private func updateView() {
        title = album.title
        
        dataSource = PhotoGridViewDataSource(album: album,
                                             collectionView: collectionView,
                                             selectedAssets: []) { [weak self] asset, indexPath, size, point in
                                                guard let weakself = self else {
                                                    return
                                                }
                                                
                                                if point.x >= (size.width / 2.0)
                                                    && point.y <= (size.height / 2.0) {
                                                    self?.dataSource?.didSelect(asset: asset, atIndexPath: indexPath)
                                                } else {
                                                    self?.showDetail(indexPath: indexPath)
                                                }
                                                
                                                weakself.updateBottomView()
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
        
        collectionView.dataSource = dataSource
        collectionView.delegate = delegate
    }
    
    private func addToolbar() {
        sendBarButton = UIBarButtonItem(title: selectionActionDisabledText, style: .plain, target: self, action: #selector(sendButtonTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [spacer, sendBarButton!]
    }
}

extension PhotoGridViewController: PhotoCarouselViewControllerDelegate {
    func selected(assets: [PHAsset]) {
        dataSource?.selectedAssets = assets
        updateBottomView()
        collectionView.reloadData()
    }
    
    @objc func sendButtonTapped() {
        guard let selectedAssets = dataSource?.selectedAssets else {
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
        dataSource?.selectedAssets.count == 0
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if (dataSource?.selectedAssets.count ?? 0) > 0 {
            let discardChangesActionSheet = UIAlertController().discardChanges(fromBarButton: navigationItem.rightBarButtonItem, withConfirmAction: {
                self.dismiss(animated: true, completion: nil)
            })
            present(discardChangesActionSheet, animated: true, completion: nil)
        }
    }
}
