
import UIKit
import Photos

protocol PhotoCarouselViewControllerDelegate: class {
    func selected(assets: [PHAsset])
    func sendButtonTapped()
}

class PhotoCarouselViewController: UIViewController {
    private let album: Album
    private let selectedPhotoIndexPath: IndexPath
    private var selectedAssets: [PHAsset] {
        didSet {
            sendBarButtonItem?.isEnabled = selectedAssets.count > 0
            sendBarButtonItem?.title = senderBarButtonText
        }
    }
    
    private var selectDeselectBarButtonItem: UIBarButtonItem?
    private var sendBarButtonItem: UIBarButtonItem?
    
    private var collectionViewDataSource: PhotoCarouselDataSource?
    private var collectionViewDelegate: PhotoCarouselDelegate?
    
    private var senderBarButtonText: String {
        return selectedAssets.count > 0 ? "Send (\(selectedAssets.count))" : "Send"
    }
    
    weak var delegate: PhotoCarouselViewControllerDelegate?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    init(album: Album,
         selectedPhotoIndexPath: IndexPath,
         selectedAssets: [PHAsset],
         delegate: PhotoCarouselViewControllerDelegate) {
        
        self.album = album
        self.selectedPhotoIndexPath = selectedPhotoIndexPath
        self.selectedAssets = selectedAssets
        self.delegate = delegate
        
        super.init(nibName: "PhotoCarouselViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(PhotoCarouselCell.nib,
                                 forCellWithReuseIdentifier: PhotoCarouselCell.reuseIdentifier)
        
        
        collectionViewDataSource = PhotoCarouselDataSource(album: album,
                                                           collectionView: collectionView,
                                                           selectedAssets: selectedAssets) { [weak self] (asset, indexPath, _, _) in
                                                            guard let weakself = self else {
                                                                return
                                                            }
                                                            
                                                            weakself.collectionViewDataSource?.didSelect(asset: asset, atIndexPath: indexPath)
                                                            weakself.selectedAssets = weakself.collectionViewDataSource?.selectedAssets ?? []
                                                            weakself.delegate?.selected(assets: weakself.selectedAssets)
                                                            weakself.updateSelectDeselectButtonTitle(withSelectedAsset: asset)
                                                            
                                                            
        }
        
        collectionViewDelegate = PhotoCarouselDelegate(viewController: self,
                                                       collectionView: collectionView) {
            return 1 // Once cell per row
        }
        
        collectionView.dataSource = collectionViewDataSource
        collectionView.delegate = collectionViewDelegate
        
        addToolbar()
        addLeftCancelBarButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: selectedPhotoIndexPath, at: .centeredHorizontally, animated: false)
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: selectedPhotoIndexPath.item))
    }
    
    private func addToolbar() {
        let sendBarButtonItem = UIBarButtonItem(title: senderBarButtonText, style: .plain, target: self, action: #selector(sendBarButtonTapped))
        let selectDeselectBarButtonItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectBarButtonTapped))
        
        sendBarButtonItem.isEnabled = selectedAssets.count > 0
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbarItems = [selectDeselectBarButtonItem, spacer, sendBarButtonItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        self.sendBarButtonItem = sendBarButtonItem
        self.selectDeselectBarButtonItem = selectDeselectBarButtonItem
    }
    
    @objc func sendBarButtonTapped() {
        delegate?.sendButtonTapped()
    }
    
    @objc func selectBarButtonTapped() {
        if let visibleCell = collectionView.visibleCells.first,
            let indexPath = collectionView.indexPath(for: visibleCell) {
            let asset = album.asset(atIndex: indexPath.row)
            collectionViewDataSource?.didSelect(asset: asset, atIndexPath: indexPath)
            selectedAssets = collectionViewDataSource?.selectedAssets ?? []
            updateSelectDeselectButtonTitle(withSelectedAsset: asset)
            delegate?.selected(assets: selectedAssets)
        }
    }
    
    private func updateSelectDeselectButtonTitle(withSelectedAsset asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectDeselectBarButtonItem?.title = "Unselect"
        } else {
            selectDeselectBarButtonItem?.title = "Select"
        }
    }
    
    func didViewPage(atIndex index: Int) {
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: index))
    }
    
    func didSelectIndex(index: Int) {
        selectBarButtonTapped()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let flowLayout = collectionView.collectionViewLayout as? PhotoCarousalFlowLayout {
            flowLayout.shouldLayoutEverything = true
            flowLayout.invalidateLayout()
        }
    }
}



