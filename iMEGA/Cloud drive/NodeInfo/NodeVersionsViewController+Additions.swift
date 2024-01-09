import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension NodeVersionsViewController {
    @objc func setToolbarActionsEnabled(_ boolValue: Bool) {
        let selectedNodesArray = self.selectedNodesArray as? [MEGANode] ?? []
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        let nodeAccessLevel = MEGASdk.shared.accessLevel(for: node).rawValue
        
        downloadBarButtonItem.isEnabled = selectedNodesArray.count == 1 && boolValue
        revertBarButtonItem.isEnabled = !isBackupNode && selectedNodesArray.count == 1 && selectedNodesArray.first?.handle != node.handle && nodeAccessLevel >= MEGAShareType.accessReadWrite.rawValue && boolValue
        removeBarButtonItem.isEnabled = nodeAccessLevel >= MEGAShareType.accessFull.rawValue && boolValue
    }
    
    @objc func configureToolbarItems() {
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        
        setToolbarItems(isBackupNode ? [downloadBarButtonItem, flexibleItem, removeBarButtonItem] : [downloadBarButtonItem, flexibleItem, revertBarButtonItem, flexibleItem, removeBarButtonItem], animated: true)
    }
    
    @objc func selectedCountTitle() -> String {
        guard let selectedCount = selectedNodesArray?.count,
              selectedCount > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
    
    @objc func open(_ node: MEGANode) {
        if node.name?.fileExtensionGroup.isVisualMedia == true {
            let sdk = MEGASdk.shared
            guard let mediaNodes = sdk.versions(for: self.node).mnz_mediaNodesMutableArrayFromNodeList() else { return }
            let displayMode: DisplayMode = self.node.mnz_isInRubbishBin() ? .rubbishBin : .nodeVersions
            let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(
                withMediaNodes: mediaNodes,
                api: sdk,
                displayMode: displayMode,
                presenting: node
            )
            self.navigationController?.present(photoBrowserVC, animated: true, completion: nil)
        } else {
            node.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: nil, chatId: nil, allNodes: nil)
        }
    }
    
    @objc func previousVersionsSection() -> NodeVersionSection {
        return sections[1]
    }
    
    @objc func allNodesSelected() -> Bool {
        return previousVersionsSection().items.count == selectedNodesArray.count
    }
    
    @objc func isNodeWithHandlePreviousVersion(_ base64Handle: String) -> Bool {
        let section = previousVersionsSection()
        return section.hasNode(base64Handle)
    }
}

@objc class NodeVersionItem: NSObject {
    @objc let node: MEGANode
    
    @objc init(node: MEGANode) {
        self.node = node
        super.init()
    }
}

@objc class NodeVersionSection: NSObject {
    
    let items: [NodeVersionItem]
    
    @objc func itemAt(index: Int) -> NodeVersionItem {
        items[index]
    }
    
    @objc func itemCount() -> Int {
        items.count
    }
    
    @objc init(items: [NodeVersionItem]) {
        self.items = items
        super.init()
    }
    
    @objc var nodes: [MEGANode] {
        var array: [MEGANode] = []
        items.forEach { item in
            array.append(item.node)
        }
        return array
    }
    
    @objc func hasNode(_ base64Handle: String) -> Bool {
        for node in nodes where node.base64Handle == base64Handle {
            return true
        }
        return false
    }
}
