
import AVKit
import Combine
import Photos
import UIKit

// MARK: - PhotoCarouselViewControllerDelegate.

protocol PhotoCarouselViewControllerDelegate: AnyObject {
    func selected(assets: [PHAsset])
    func sendButtonTapped()
}

// MARK: - PhotoCarouselViewController.

final class PhotoCarouselViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Private instance variables.
    
    private let album: Album
    private let selectedPhotoIndexPath: IndexPath
    private var selectedAssets: [PHAsset] {
        didSet {
            sendBarButtonItem?.isEnabled = selectedAssets.isNotEmpty
            sendBarButtonItem?.title = senderBarButtonText
        }
    }
    
    private let selectionActionType: AlbumsSelectionActionType
    private let selectionActionDisabledText: String
    
    private var selectDeselectBarButtonItem: UIBarButtonItem?
    private var sendBarButtonItem: UIBarButtonItem?
    
    private var collectionViewDataSource: PhotoCarouselDataSource?
    private var collectionViewDelegate: PhotoCarouselDelegate?
    
    private var playerItemDidPlayToEndTimeSubscription: AnyCancellable?
    
    private var senderBarButtonText: String {
        return selectedAssets.isNotEmpty ? selectionActionType.localizedTextWithCount(selectedAssets.count) : selectionActionDisabledText
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .mnz_label()
        return label
    }()
    
    private var currentIndexPath: IndexPath? {
        if let visibleCell = collectionView.visibleCells.first,
            let indexPath = collectionView.indexPath(for: visibleCell) {
            return indexPath
        }
        
        return nil
    }
    
    weak private var delegate: PhotoCarouselViewControllerDelegate?
    
    // MARK: - Initializers.

    init(album: Album,
         selectedPhotoIndexPath: IndexPath,
         selectedAssets: [PHAsset],
         selectionActionType: AlbumsSelectionActionType,
         selectionActionDisabledText: String,
         delegate: PhotoCarouselViewControllerDelegate) {
        
        self.album = album
        self.selectedPhotoIndexPath = selectedPhotoIndexPath
        self.selectedAssets = selectedAssets
        self.selectionActionType = selectionActionType
        self.selectionActionDisabledText = selectionActionDisabledText
        self.delegate = delegate
        
        super.init(nibName: "PhotoCarouselViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View controller lifecycle methods.
    
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
        addRightCancelBarButtonItem()
        
        updateTitleView(withAssetIndex: selectedPhotoIndexPath.item)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFlowLayoutCurrentPage(withIndex: selectedPhotoIndexPath.item)
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: selectedPhotoIndexPath.item))
        album.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        album.delegate = nil
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let flowLayout = collectionView.collectionViewLayout as? PhotoCarouselFlowLayout {
            flowLayout.relayout()
        }
    }
    
    // MARK: - Interface methods.
    
    func didViewPage(atIndex index: Int) {
        updateFlowLayoutCurrentPage(withIndex: index)
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: index))
        updateTitleView(withAssetIndex: index)
    }
    
    func didSelect(indexPath: IndexPath) {
        let asset = album.asset(atIndex: indexPath.item)
        if asset.mediaType == .video {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
            
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            
            PHCachingImageManager().requestPlayerItem(forVideo: asset, options: options) { [weak self] (playerItem, info) in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    
                    if let info = info,
                        let error = info[PHImageErrorKey] as? NSError {
                        let alertController = UIAlertController(title: nil,
                                                                message: error.localizedDescription,
                                                                preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel, handler: nil))
                        self?.present(alertController, animated: true, completion: nil)
                        MEGALogError("[Photo Carousel View] unable to play video \(error.localizedDescription)")
                        return
                    }
                    
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = AVPlayer(playerItem: playerItem)
                    self?.present(playerViewController, animated: true) {
                        self?.loaded(playerViewController: playerViewController)
                    }
                }
            }
        }
    }
    
    func selectAsset(atIndexPath indexPath: IndexPath) {
        let asset = album.asset(atIndex: indexPath.row)
        collectionViewDataSource?.didSelect(asset: asset, atIndexPath: indexPath)
        selectedAssets = collectionViewDataSource?.selectedAssets ?? []
        updateSelectDeselectButtonTitle(withSelectedAsset: asset)
        delegate?.selected(assets: selectedAssets)
    }
    
    // MARK: - Private methods.
    
    private func loaded(playerViewController: AVPlayerViewController) {
        playerViewController.player?.play()
        
        playerItemDidPlayToEndTimeSubscription = NotificationCenter.default
            .publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                playerViewController.dismissView()
                self?.playerItemDidPlayToEndTimeSubscription?.cancel()
                self?.playerItemDidPlayToEndTimeSubscription = nil
            }
    }
    
    @objc private func sendBarButtonTapped() {
        delegate?.sendButtonTapped()
    }
    
    @objc private func selectBarButtonTapped() {
        if let indexPath = currentIndexPath {
            selectAsset(atIndexPath: indexPath)
        }
    }
    
    private func updateSelectDeselectButtonTitle(withSelectedAsset asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectDeselectBarButtonItem?.title = Strings.Localizable.unselect
        } else {
            selectDeselectBarButtonItem?.title = Strings.Localizable.select
        }
    }
        
    private func addToolbar() {
        let sendBarButtonItem = UIBarButtonItem(title: senderBarButtonText,
                                                style: .plain,
                                                target: self,
                                                action: #selector(sendBarButtonTapped))
        let selectDeselectBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.select,
            style: .plain,
            target: self,
            action: #selector(selectBarButtonTapped)
        )
        
        sendBarButtonItem.isEnabled = selectedAssets.isNotEmpty
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbarItems = [selectDeselectBarButtonItem, spacer, sendBarButtonItem]
        navigationController?.setToolbarHidden(false, animated: false)
        
        self.sendBarButtonItem = sendBarButtonItem
        self.selectDeselectBarButtonItem = selectDeselectBarButtonItem
    }
    
    private func updateTitleView(withAssetIndex index: Int) {
        let asset = album.asset(atIndex: index)
        titleLabel.attributedText = asset.attributedTitleString
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }
    
    private func updateFlowLayoutCurrentPage(withIndex index: Int) {
        if let flowLayout = collectionView.collectionViewLayout as? PhotoCarouselFlowLayout {
            flowLayout.currentPage = index
        }
    }
}

extension PhotoCarouselViewController: AlbumDelegate {
    
    func didResetFetchResult() {
        collectionView.reloadData()
    }

    func didChange(removedIndexPaths: [IndexPath]?,
                   insertedIndexPaths: [IndexPath]?,
                   changedIndexPaths: [IndexPath]?) {
        
        if let removedIndexPaths = removedIndexPaths,
              let changedIndexPaths = changedIndexPaths,
              !Set(changedIndexPaths).isDisjoint(with: removedIndexPaths) {
            collectionView.reloadData()
            return
        }
        
        if let lastIndex = removedIndexPaths?.last?.item, lastIndex >= album.assetCount() {
            collectionView.reloadData()
            return
        }
        
        var newIndexPath: IndexPath?
        var snapshotView: UIView?
        
        // Plan is to get the current asset and make sure it is not being deleted
        if let currentIndexPath = currentIndexPath,
            let asset = collectionViewDataSource?.asset(atIndexPath: currentIndexPath) {
            
            let indexPath = IndexPath(item: album.index(asset: asset), section: 0)
            if currentIndexPath != indexPath {
                newIndexPath = indexPath
                
                snapshotView = view.snapshotView(afterScreenUpdates: false)
                if let snapshotView = snapshotView {
                    view.addSubview(snapshotView)
                    snapshotView.autoPinEdgesToSuperviewEdges()
                }
            }
        }
        
        collectionView.performBatchUpdates({
            if let removedIndexPaths = removedIndexPaths {
                removeSelectedAssets(forIndexPaths: removedIndexPaths)
                collectionView.deleteItems(at: removedIndexPaths)
            }
            
            if let insertedIndexPaths = insertedIndexPaths {
                collectionView.insertItems(at: insertedIndexPaths)
            }
            
            if let changedIndexPaths = changedIndexPaths {
                collectionView.reloadItems(at: changedIndexPaths)
            }
        }, completion: { _ in
            if let newIndexPath = newIndexPath {
                self.collectionView.scrollToItem(at: newIndexPath,
                                                 at: .centeredHorizontally,
                                                 animated: false)
                self.didViewPage(atIndex: newIndexPath.item)
                snapshotView?.removeFromSuperview()
            }
        })
    }
    
    private func removeSelectedAssets(forIndexPaths indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCarouselCell,
                let asset = cell.asset,
                let index = selectedAssets.firstIndex(of: asset) {
                selectedAssets.remove(at: index)
            }
        }
        
        delegate?.selected(assets: selectedAssets)
    }
}

// MARK: - PHAsset extension Helper.

fileprivate extension PHAsset {
    var attributedTitleString: NSAttributedString? {
        guard let assetCreationDate = creationDate else {
            return nil
        }
        
        let attributedDateString = NSMutableAttributedString(
            string: assetCreationDate.dateString + "\n",
            attributes: [NSAttributedString.Key.font:
                UIFont.systemFont(ofSize: 16.0, weight: .semibold)]
        )
        
        attributedDateString.append(
            NSAttributedString(string: assetCreationDate.timeString,
                               attributes: [NSAttributedString.Key.font:
                                UIFont.systemFont(ofSize: 13.0, weight: .regular)])
        )
        
        return attributedDateString
    }
}

// MARK: - Date Extension Helper.

fileprivate extension Date {
    var dateString: String {
        let format = isThisYear ? "MMMM dd" : "MMMM dd, yyyy"
        return string(dateFormat: format)
    }
    
    var timeString: String {
        let format = "HH:mm"
        return string(dateFormat: format)
    }

    private func string(dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.autoupdatingCurrent
        return dateFormatter.string(from: self)
    }
}
