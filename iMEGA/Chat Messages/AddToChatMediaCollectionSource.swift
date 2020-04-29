
protocol AddToChatMediaCollectionSourceDelegate: class {
    func moreButtonTapped()
    func sendAsset(asset: PHAsset)
    func cameraButtonTapped()
}

class AddToChatMediaCollectionSource: NSObject {
    private let collectionView: UICollectionView
    private let maxNumberOfAssetsFetched = 16
    private var lastSelectedIndexPath:IndexPath?
    private weak var delegate: AddToChatMediaCollectionSourceDelegate?

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
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let assetCounts = (fetchResult.count > maxNumberOfAssetsFetched) ? maxNumberOfAssetsFetched : fetchResult.count
        return 1 + assetCounts
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier,
                                                          for: indexPath) as! AddToChatCameraCollectionCell
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatImageCell.reuseIdentifier,
                                                          for: indexPath) as! AddToChatImageCell
            cell.asset = fetchResult.object(at: indexPath.item-1)
            if lastSelectedIndexPath == indexPath {
                cell.selectedView.isHidden = false
            }
            
            if indexPath.item == (collectionView.numberOfItems(inSection: 0) - 1) {
                cell.cellType = .more
            }
            
            return cell
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
        
        if let imageCell = collectionView.cellForItem(at: indexPath) as? AddToChatImageCell {
            
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
        }
    }
}
