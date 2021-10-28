
import Foundation

final class FolderLinkCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    private weak var controller: FolderLinkCollectionViewController?
    
    init(controller: FolderLinkCollectionViewController) {
        self.controller = controller
        super.init()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if MEGAReachabilityManager.isReachable() {
            return Int(ThumbnailSection.count.rawValue)
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let controller = controller else { return 0 }
        return section == ThumbnailSection.file.rawValue ? controller.fileList.count : controller.folderList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellId = indexPath.section == 1 ? "NodeCollectionFileID" : "NodeCollectionFolderID"
        
        guard let controller = controller,
              let node = controller.getNode(at: indexPath),
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? NodeCollectionViewCell else {
            MEGALogDebug("Could not instantiate NodeCollectionViewCell or Node at index")
            return UICollectionViewCell()
        }
        
        cell.configureCell(for: node, api:MEGASdkManager.sharedMEGASdkFolder())
        cell.selectImageView?.isHidden = !collectionView.allowsMultipleSelection
        cell.moreButton?.isHidden = collectionView.allowsMultipleSelection
        
        if node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil {
            cell.downloadedImageView?.isHidden = false
        } else {
            cell.downloadedImageView?.isHidden = true
        }
        
        return cell
    }
}

