import MEGAAssets
import MEGADomain
import MEGARepo
import MEGASDKRepo

@objc final class NodeAssetsManager: NSObject {
    @objc static var shared = NodeAssetsManager(sdk: .shared)
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    @objc func icon(for node: MEGANode) -> UIImage {
        switch node.type {
        case .file:
            return image(for: ((node.name ?? "") as NSString).pathExtension)
        case .folder:
            if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
                return UIImage.folderChat
            }
            if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
                return UIImage.filetypeFolderCamera
            }
#if MAIN_APP_TARGET
            if BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupDeviceFolder(node.toNodeEntity()) {
                return backupDeviceIcon(for: node)
            }
#endif
            return commonFolderImage(for: node)
        case .incoming:
            return node.isFolder() ? commonFolderImage(for: node) : UIImage(resource: .filetypeGeneric)
        default:
            return UIImage(resource: .filetypeGeneric)
        }
    }
    
    @objc func image(for extension: String) -> UIImage {
        MEGAAssetsImageProvider.fileTypeResource(forFileExtension: `extension`)
    }
            
    private func commonFolderImage(for node: MEGANode) -> UIImage {
        if node.isInShare() {
            return UIImage.folderIncoming
        } else if node.isOutShare() {
            return UIImage.folderOutgoing
        } else {
            return UIImage(resource: .filetypeFolder)
        }
    }
    
    private func backupDeviceIcon(for node: MEGANode) -> UIImage {
        guard node.deviceId != nil, let nodeName = node.name, !nodeName.isEmpty else { return commonFolderImage(for: node) }
        let nodeNameLowerCased = nodeName.lowercased()
        
        if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.win.toRegexString()) {
            return UIImage.pcWindows
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.linux.toRegexString()) {
            return UIImage.pcLinux
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.mac.toRegexString()) {
            return UIImage.pcMac
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.drive.toRegexString()) {
            return UIImage.drive
        } else {
            return UIImage.pc
        }
    }
}

extension NodeAssetsManager: NodeIconRepositoryProtocol {
    func iconData(for node: MEGADomain.NodeEntity) -> Data {
        guard let megaNode = node.toMEGANode(in: sdk),
              let icon = icon(for: megaNode).pngData() else {
            return Data()
        }
        return icon
    }
}
