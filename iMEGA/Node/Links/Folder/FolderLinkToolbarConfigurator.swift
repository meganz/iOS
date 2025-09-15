import Foundation
import MEGAAssets

final class FolderLinkToolbarConfigurator {
    typealias FolderLinkToolbarButtonAction = (UIBarButtonItem) -> Void
    
    let importAction: FolderLinkToolbarButtonAction
    let downloadAction: FolderLinkToolbarButtonAction
    let saveToPhotosAction: FolderLinkToolbarButtonAction
    let shareLinkAction: FolderLinkToolbarButtonAction
    
    private(set) var activeBarButtons: [UIBarButtonItem] = []
    
    lazy var flexibleItem = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
    )
    
    lazy var importItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.import,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var downloadItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.offline,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var saveToPhotosItem = UIBarButtonItem(
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
    
    /// Builds toolbar items using the current selection.
    /// - Parameters:
    ///   - allNodes: Nodes currently displayed in the folder link.
    ///   - selectedNodes: Current selection (if any). When empty or nil, `allNodes` is used to decide Save to Photos visibility.
    func toolbarItems(allNodes: [MEGANode]?, selectedNodes: [MEGANode]?) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = [
            importItem,
            flexibleItem,
            downloadItem,
            flexibleItem,
            shareLinkItem
        ]
        
        let allSelectedNodesAreMedia = (selectedNodes?.isNotEmpty == true) && areAllMediaNodes(selectedNodes ?? [])
        let allNodesMediaWhenNoSelection = (selectedNodes?.isEmpty ?? true) && areAllMediaNodes(allNodes ?? [])
        
        if allSelectedNodesAreMedia || allNodesMediaWhenNoSelection {
            items.insert(contentsOf: [saveToPhotosItem, flexibleItem], at: 4)
        }
        
        activeBarButtons = items.filter { $0 !== flexibleItem }
        return items
    }
    
    func setToolbarButtonsEnabled(_ enabled: Bool) {
        activeBarButtons.forEach { $0.isEnabled = enabled }
    }
    
    private func areAllMediaNodes(_ nodes: [MEGANode]) -> Bool {
        nodes.allSatisfy { $0.name?.fileExtensionGroup.isVisualMedia == true }
    }
}
