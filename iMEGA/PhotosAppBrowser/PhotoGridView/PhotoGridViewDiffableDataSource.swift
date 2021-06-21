import UIKit
import Photos

@available(iOS 13.0, *)
final class PhotoGridViewDiffableDataSource {
    private enum Section {
        case main
    }
    
    private weak var collectionView: UICollectionView?
    typealias SelectionHandler = (PHAsset, IndexPath, CGSize, CGPoint) -> Void
    private let selectionHandler: SelectionHandler
    private var dataSource: UICollectionViewDiffableDataSource<Section, PHAsset>?
    var selectedAssets: [PHAsset]

    init(collectionView: UICollectionView, selectedAssets: [PHAsset], selectionHandler: @escaping SelectionHandler) {
        self.collectionView = collectionView
        self.selectedAssets = selectedAssets
        self.selectionHandler = selectionHandler
    }
    
    func load(assets: [PHAsset]) {
        selectedAssets = selectedAssets.reduce(into: []) { result, asset in
            if assets.contains(asset) {
                result.append(asset)
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, PHAsset>()
        snapshot.appendSections([.main])
        snapshot.appendItems(assets)
        snapshot.reloadItems(selectedAssets)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func reload(assets: [PHAsset]) {
        guard var newSnapshot = dataSource?.snapshot() else { return }
        newSnapshot.reloadItems(assets)
        dataSource?.apply(newSnapshot)
    }
    
    func configureDataSource() {
        guard let collectionView = collectionView else { return }
        
        dataSource = UICollectionViewDiffableDataSource<Section, PHAsset>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, asset: PHAsset) -> UICollectionViewCell? in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridViewCell.reuseIdentifier,
                                                                for: indexPath) as? PhotoGridViewCell else {
                return UICollectionViewCell()
            }
            
            cell.asset = asset
            cell.selectedIndex = self.selectedAssets.firstIndex(of: asset)
            
            cell.tapHandler = { instance, size, point in
                guard let selectedAsset = instance.asset else {
                    return
                }
                self.selectionHandler(selectedAsset, indexPath, size, point)
            }
            
            cell.durationString = (asset.mediaType == .video) ? asset.duration.timeDisplayString() : nil
            return cell
        }
    }
    
    func didSelect(asset: PHAsset) {
        let reloadAssets: [PHAsset]
        if let index = selectedAssets.firstIndex(of: asset) {
            reloadAssets = Array(selectedAssets[index..<selectedAssets.count])
            selectedAssets.remove(at: index)
        } else {
            selectedAssets.append(asset)
            reloadAssets = [asset]
        }
        
        reload(assets: reloadAssets)
    }
}
