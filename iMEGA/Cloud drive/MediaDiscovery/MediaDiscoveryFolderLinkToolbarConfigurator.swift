import Foundation
import MEGAAssets

final class MediaDiscoveryFolderLinkToolbarConfigurator {
    typealias FolderLinkToolbarButtonAction = (UIBarButtonItem) -> Void
    
    let importAction: FolderLinkToolbarButtonAction
    let downloadAction: FolderLinkToolbarButtonAction
    let saveToPhotosAction: FolderLinkToolbarButtonAction
    let shareLinkAction: FolderLinkToolbarButtonAction
    
    private lazy var flexibleItem = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
    )
    
    private lazy var importItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.import,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    private lazy var downloadItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.offline,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    private lazy var saveToPhotosItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.saveToPhotos,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var shareLinkItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.link,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    init(importAction: @escaping FolderLinkToolbarButtonAction,
         downloadAction: @escaping FolderLinkToolbarButtonAction,
         saveToPhotosAction: @escaping FolderLinkToolbarButtonAction,
         shareLinkAction: @escaping FolderLinkToolbarButtonAction) {
        self.importAction = importAction
        self.downloadAction = downloadAction
        self.saveToPhotosAction = saveToPhotosAction
        self.shareLinkAction = shareLinkAction
    }
    
    @objc func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case importItem:
            importAction(barButtonItem)
        case downloadItem:
            downloadAction(barButtonItem)
        case saveToPhotosItem:
            saveToPhotosAction(barButtonItem)
        case shareLinkItem:
            shareLinkAction(barButtonItem)
        default:
            break
        }
    }
    
    func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        let isEnabled = nodes?.isNotEmpty == true
        let barButtonItems = [importItem,
                              flexibleItem,
                              downloadItem,
                              flexibleItem,
                              saveToPhotosItem,
                              flexibleItem,
                              shareLinkItem]
        barButtonItems.forEach {
          $0.isEnabled = isEnabled
        }
        return barButtonItems
    }
}
