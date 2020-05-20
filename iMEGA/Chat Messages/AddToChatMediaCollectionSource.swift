
protocol AddToChatMediaCollectionSourceDelegate: class {
    func moreButtonTapped()
    func sendAsset(asset: PHAsset)
    func showCamera()
}

class AddToChatMediaCollectionSource: NSObject {
    private let collectionView: UICollectionView
    private let maxNumberOfAssetsFetched = 16
    private var lastSelectedIndexPath:IndexPath?
    private weak var delegate: AddToChatMediaCollectionSourceDelegate?
    
    private let minimumLineSpacing: CGFloat = 5.0
    private let cellDefaultWidth: CGFloat = 100.0

    private var hasAuthorizedAccessToPhotoAlbum: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    private lazy var fetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxNumberOfAssetsFetched
        return PHAsset.fetchAssets(with: fetchOptions)
    }()
    
    init(collectionView: UICollectionView, delegate: AddToChatMediaCollectionSourceDelegate) {
        self.collectionView = collectionView
        self.delegate = delegate
        
        super.init()
        
        collectionView.register(AddToChatCameraCollectionCell.nib,
                                   forCellWithReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier)
        collectionView.register(AddToChatImageCell.nib,
                                forCellWithReuseIdentifier: AddToChatImageCell.reuseIdentifier)
        collectionView.register(AddToChatAllowAccessCollectionCell.nib,
                                forCellWithReuseIdentifier: AddToChatAllowAccessCollectionCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if hasAuthorizedAccessToPhotoAlbum {
            let assetCounts = (fetchResult.count > maxNumberOfAssetsFetched) ? maxNumberOfAssetsFetched : fetchResult.count
            return 1 + assetCounts
        }
        
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier,
                                                          for: indexPath) as! AddToChatCameraCollectionCell
            
            if !(AVCaptureDevice.authorizationStatus(for: .video) == .authorized) {
                cell.hideLiveFeedView()
            }

            return cell
            
        default:
            if hasAuthorizedAccessToPhotoAlbum {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatImageCell.reuseIdentifier,
                                                              for: indexPath) as! AddToChatImageCell
                cell.asset = fetchResult.object(at: indexPath.item-1)
                cell.selectedView.isHidden = !(lastSelectedIndexPath == indexPath) 
                
                if indexPath.item == (collectionView.numberOfItems(inSection: 0) - 1) {
                    cell.cellType = .more
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
        guard let cameraCell = cell as? AddToChatCameraCollectionCell,
            !cameraCell.isCurrentShowingLiveFeed else {
            return
        }
        
        do {
            try cameraCell.showLiveFeed()
        } catch {
            print("camera live feed error \(error.localizedDescription)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let cell = collectionView.cellForItem(at: indexPath)
        
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
                    let imageCell = collectionView.cellForItem(at: lastSelectedIndexPath) as? AddToChatImageCell {
                    imageCell.toggleSelection()
                }
                
                self.lastSelectedIndexPath = indexPath
                imageCell.toggleSelection()
            }
        } else if cell is AddToChatAllowAccessCollectionCell {
            DevicePermissionsHelper.photosPermission { granted in
                if granted {
                    self.collectionView.reloadData()
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            }
        } else if cell is AddToChatCameraCollectionCell {
            DevicePermissionsHelper.videoPermission { videoPermissionGranted in
                if videoPermissionGranted {
                    DevicePermissionsHelper.photosPermission { photosPermissionGranted in
                        if photosPermissionGranted {
                            self.delegate?.showCamera()
                        } else {
                            DevicePermissionsHelper.alertPhotosPermission()
                        }
                    }
                } else {
                    DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
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
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }
}
