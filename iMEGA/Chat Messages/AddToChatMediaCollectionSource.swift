import MEGAPermissions

protocol AddToChatMediaCollectionSourceDelegate: AnyObject {
    func moreButtonTapped()
    func sendAsset(asset: PHAsset)
    func showCamera()
    func dismissView()
}

class AddToChatMediaCollectionSource: NSObject {
    private let collectionView: UICollectionView
    private let maxNumberOfAssetsFetched = 16
    private var lastSelectedIndexPath: IndexPath?
    private weak var delegate: (any AddToChatMediaCollectionSourceDelegate)?
    private var fetchResult: PHFetchResult<PHAsset>?
    private let permissionHandler: any DevicePermissionsHandling
    private let minimumLineSpacing: CGFloat = 2.0
    private let cellDefaultWidth: CGFloat = 100.0
    
    private lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxNumberOfAssetsFetched
        return fetchOptions
    }()
    
    var showLiveFeedIfRequired = false {
        didSet {
            if showLiveFeedIfRequired,
                let cameraCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? AddToChatCameraCollectionCell,
               permissionHandler.isVideoPermissionAuthorized,
                !cameraCell.isCurrentShowingLiveFeed {
                do {
                    try cameraCell.showLiveFeed()
                } catch {
                    MEGALogDebug("camera live feed error \(error.localizedDescription)")
                }
            }
        }
    }
    
    init(
        collectionView: UICollectionView,
        delegate: some AddToChatMediaCollectionSourceDelegate,
        permissionHandler: some DevicePermissionsHandling
    ) {
        self.collectionView = collectionView
        self.delegate = delegate
        self.permissionHandler = permissionHandler
        super.init()
        
        updateFetchResult()
        
        collectionView.register(AddToChatCameraCollectionCell.nib,
                                   forCellWithReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier)
        collectionView.register(AddToChatImageCell.nib,
                                forCellWithReuseIdentifier: AddToChatImageCell.reuseIdentifier)
        collectionView.register(AddToChatAllowAccessCollectionCell.nib,
                                forCellWithReuseIdentifier: AddToChatAllowAccessCollectionCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private var hasAuthorizedAccessToPhotoAlbum: Bool {
        permissionHandler.hasAuthorizedAccessToPhotoAlbum
    }
    
    private func updateFetchResult() {
        if hasAuthorizedAccessToPhotoAlbum {
            self.fetchResult = PHAsset.fetchAssets(with: self.fetchOptions)
        }
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let cameraCellCount = 1
        let photosErrorCellCount = 1
        
        guard hasAuthorizedAccessToPhotoAlbum else {
            return cameraCellCount + photosErrorCellCount
        }
        
        updateFetchResult()
        guard let fetchResult = fetchResult else {
            return cameraCellCount + photosErrorCellCount
        }
        
        let assetCounts = (fetchResult.count > maxNumberOfAssetsFetched) ? maxNumberOfAssetsFetched : fetchResult.count
        return cameraCellCount + assetCounts

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier,
                                                          for: indexPath) as! AddToChatCameraCollectionCell
            
            if !permissionHandler.isVideoPermissionAuthorized {
                cell.hideLiveFeedView()
            }

            return cell
            
        default:
            if hasAuthorizedAccessToPhotoAlbum {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatImageCell.reuseIdentifier,
                                                              for: indexPath) as! AddToChatImageCell
                
                if let fetchResult = fetchResult {
                    cell.asset = fetchResult.object(at: indexPath.item-1)
                    cell.cellType = (
                        fetchResult.count >= maxNumberOfAssetsFetched
                            && (indexPath.item == collectionView.numberOfItems(inSection: 0) - 1)
                        ) ? .more : .media
                }
                
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatAllowAccessCollectionCell.reuseIdentifier,
                                                              for: indexPath) as! AddToChatAllowAccessCollectionCell
                
                return cell
            }
        }
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if let cameraCell = cell as? AddToChatCameraCollectionCell,
            !cameraCell.isCurrentShowingLiveFeed {
            
            if showLiveFeedIfRequired {
                do {
                    try cameraCell.showLiveFeed()
                } catch {
                    MEGALogDebug("camera live feed error \(error.localizedDescription)")
                }
            } else {
                cameraCell.prepareToShowLivefeed()
            }
            
        } else if let imageCell = cell as? AddToChatImageCell, imageCell.cellType == .media {
            imageCell.foregroundView.isHidden = !(lastSelectedIndexPath == indexPath)
        }
    }
    
    var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let cell = collectionView.cellForItem(at: indexPath)
        
        let dismissIfiPad = { [weak self] in
            if UIDevice.current.iPad {
                self?.delegate?.dismissView()
            }
        }
        
        if let imageCell = cell as? AddToChatImageCell {
            
            guard imageCell.cellType != .more else {
                delegate?.moreButtonTapped()
                return
            }

            if lastSelectedIndexPath == indexPath {
                guard let delegate = delegate,
                    let asset = imageCell.asset else {
                    return
                }
                
                delegate.sendAsset(asset: asset)
            } else {
                if let lastSelectedIndexPath = lastSelectedIndexPath,
                    let previousSelectedCell = collectionView.cellForItem(at: lastSelectedIndexPath) as? AddToChatImageCell {
                    previousSelectedCell.toggleSelection()
                }
                
                self.lastSelectedIndexPath = indexPath
                imageCell.toggleSelection()
            }
        } else if cell is AddToChatAllowAccessCollectionCell {
            permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
                guard let self else { return }
                if granted {
                    self.collectionView.reloadData()
                } else {
                    dismissIfiPad()
                    permissionRouter.alertPhotosPermission()
                }
            }
        } else if cell is AddToChatCameraCollectionCell {
            permissionHandler.requestVideoPermission { [weak self] videoPermissionGranted in
                guard let self else { return }
                
                guard videoPermissionGranted else {
                    dismissIfiPad()
                    permissionRouter.alertVideoPermission()
                    return
                }
                
                permissionHandler.photosPermissionWithCompletionHandler {[weak self] photosPermissionGranted in
                    guard let self else { return }
                    if photosPermissionGranted {
                        delegate?.showCamera()
                    } else {
                        dismissIfiPad()
                        permissionRouter.alertPhotosPermission()
                    }
                }
            }
        }
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 1 && !hasAuthorizedAccessToPhotoAlbum {
            return CGSize(width: collectionView.bounds.width - (cellDefaultWidth + minimumLineSpacing),
                          height: 110)
        }
        
        return CGSize(width: cellDefaultWidth, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }
}
