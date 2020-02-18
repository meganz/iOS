
import UIKit
import Photos
import AVKit

// MARK:- PhotoCarouselViewControllerDelegate.

protocol PhotoCarouselViewControllerDelegate: class {
    func selected(assets: [PHAsset])
    func sendButtonTapped()
}

// MARK:- PhotoCarouselViewController.

class PhotoCarouselViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK:- Private instance variables.
    
    private let album: Album
    private let selectedPhotoIndexPath: IndexPath
    private var selectedAssets: [PHAsset] {
        didSet {
            sendBarButtonItem?.isEnabled = selectedAssets.count > 0
            sendBarButtonItem?.title = senderBarButtonText
        }
    }
    
    private let selectionActionText: String
    private let selectionActionDisabledText: String
    
    private var selectDeselectBarButtonItem: UIBarButtonItem?
    private var sendBarButtonItem: UIBarButtonItem?
    
    private var collectionViewDataSource: PhotoCarouselDataSource?
    private var collectionViewDelegate: PhotoCarouselDelegate?
    
    private var senderBarButtonText: String {
        return selectedAssets.count > 0 ? String(format: selectionActionText, selectedAssets.count) : selectionActionDisabledText
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    weak private var delegate: PhotoCarouselViewControllerDelegate?
    
    // MARK:- Initializers.

    init(album: Album,
         selectedPhotoIndexPath: IndexPath,
         selectedAssets: [PHAsset],
         selectionActionText: String,
         selectionActionDisabledText: String,
         delegate: PhotoCarouselViewControllerDelegate) {
        
        self.album = album
        self.selectedPhotoIndexPath = selectedPhotoIndexPath
        self.selectedAssets = selectedAssets
        self.selectionActionText = selectionActionText
        self.selectionActionDisabledText = selectionActionDisabledText
        self.delegate = delegate
        
        super.init(nibName: "PhotoCarouselViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- View controller lifecycle methods.
    
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
        
        updateTitleView(withAssetIndex: selectedPhotoIndexPath.item)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFlowLayoutCurrentPage(withIndex: selectedPhotoIndexPath.item)
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: selectedPhotoIndexPath.item))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let flowLayout = collectionView.collectionViewLayout as? PhotoCarousalFlowLayout {
            flowLayout.relayout()
        }
    }
    
    // MARK:- Orientation method.

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK:- Interface methods.
    
    func didViewPage(atIndex index: Int) {
        updateFlowLayoutCurrentPage(withIndex: index)
        updateSelectDeselectButtonTitle(withSelectedAsset: album.asset(atIndex: index))
        updateTitleView(withAssetIndex: index)
    }
    
    func didSelectIndex(index: Int) {
        let asset = album.asset(atIndex: index)
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
                        alertController.addAction(UIAlertAction(title: "ok".localized(), style: .cancel, handler: nil))
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
    
    // MARK:- Private methods.
    
    private func loaded(playerViewController: AVPlayerViewController) {
        playerViewController.player?.play()
        
        let center = NotificationCenter.default
        var token: NSObjectProtocol?
        
        token = center.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                   object: nil,
                                   queue: OperationQueue.main) { _ in
                                    playerViewController.dismissView()
                                    center.removeObserver(token!)
        }
    }
    
    @objc private func sendBarButtonTapped() {
        delegate?.sendButtonTapped()
    }
    
    @objc private func selectBarButtonTapped() {
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
            selectDeselectBarButtonItem?.title = "Unselect".localized(comment: "Used in Photos app browser carousel view to unselect a selected photo.")
        } else {
            selectDeselectBarButtonItem?.title = "select".localized(comment: "Used in Photos app browser carousel view to select a photo.")
        }
    }
        
    private func addToolbar() {
        let sendBarButtonItem = UIBarButtonItem(title: senderBarButtonText,
                                                style: .plain,
                                                target: self,
                                                action: #selector(sendBarButtonTapped))
        let selectDeselectBarButtonItem = UIBarButtonItem(
            title: "select".localized(comment: "Used in Photos app browser carousel view to select a photo."),
            style: .plain,
            target: self,
            action: #selector(selectBarButtonTapped)
        )
        
        sendBarButtonItem.isEnabled = selectedAssets.count > 0
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
        if let flowLayout = collectionView.collectionViewLayout as? PhotoCarousalFlowLayout {
            flowLayout.currentPage = index
        }
    }
}

// MARK:- PHAsset extension Helper.

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

// MARK:- Date Extension Helper.

fileprivate extension Date {
    var dateString: String {
        let format = isThisYear ? "MMMM dd" : "MMMM dd, yyyy"
        return string(dateFormat: format)
    }
    
    var timeString: String {
        let format = "HH:mm"
        return string(dateFormat: format)
    }
    
    private var isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    private func string(dateFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: self)
    }
}



