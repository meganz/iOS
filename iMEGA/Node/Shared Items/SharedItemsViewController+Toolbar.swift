import MEGAAssets
import UIKit

@objc
extension SharedItemsViewController {
    func setupToolbar() {
        let newToolbar = UIToolbar()
        newToolbar.translatesAutoresizingMaskIntoConstraints = false
        newToolbar.backgroundColor = UIColor.surface1Background()
        newToolbar.alpha = 0
        newToolbar.isHidden = true
        
        view.addSubview(newToolbar)
        
        NSLayoutConstraint.activate([
            newToolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            newToolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            newToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        toolbar = newToolbar
        
        configureSharedItemsToolbarButtons()
        configToolbarItemsForSharedItems()
    }
    
    func setToolbarVisible(_ visible: Bool, animated: Bool) {
        let height = toolbar.bounds.height
        
        let changes = {
            self.toolbar.isHidden = !visible
            self.toolbar.alpha = visible ? 1 : 0
            
            var inset = self.tableView?.contentInset ?? .zero
            inset.bottom = visible ? height : 0
            self.tableView?.contentInset = inset
            self.tableView?.scrollIndicatorInsets = inset
        }
        
        if animated {
            UIView.animate(withDuration: 0.33, animations: changes)
        } else {
            changes()
        }
    }
    
    private func configureSharedItemsToolbarButtons() {
        downloadBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.offline,
            action: NSSelectorFromString("downloadAction:")
        )
        
        carbonCopyBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.copy,
            action: NSSelectorFromString("copyAction:")
        )
        
        leaveShareBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.leaveShare,
            action: NSSelectorFromString("leaveShareAction:")
        )
        
        shareLinkBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.link,
            action: NSSelectorFromString("shareLinkAction:")
        )
        
        removeLinkBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.removeLink,
            action: NSSelectorFromString("removeLinkAction:")
        )
        
        shareFolderBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.shareFolder,
            action: NSSelectorFromString("shareFolderAction:")
        )
        
        removeShareBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.removeShare,
            action: NSSelectorFromString("removeShareAction:")
        )
        
        saveToPhotosBarButtonItem = makeBarButtonItem(
            image: MEGAAssets.UIImage.saveToPhotos,
            action: NSSelectorFromString("saveToPhotosAction:")
        )
    }
    
    private func makeBarButtonItem(image: UIImage, action: Selector) -> UIBarButtonItem {
        UIBarButtonItem(image: image, style: .plain, target: self, action: action)
    }
}
