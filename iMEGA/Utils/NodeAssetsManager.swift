import MEGADomain

@objc final class NodeAssetsManager: NSObject {
    @objc static var shared = NodeAssetsManager()
    
    @objc func icon(for node: MEGANode) -> UIImage {
        switch node.type {
        case .file:
            return image(for: ((node.name ?? "") as NSString).pathExtension)
        case .folder:
            if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
                return Asset.Images.Filetypes.folderChat.image
            }
#if MAIN_APP_TARGET
            if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
                return Asset.Images.Filetypes.folderImage.image
            } else if MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo).isBackupDeviceFolder(node.toNodeEntity()) {
                return backupDeviceIcon(for: node)
            }
#endif
            return commonFolderImage(for: node)
        case .incoming:
            return node.isFolder() ? commonFolderImage(for: node) : Asset.Images.Filetypes.generic.image
        default:
            return Asset.Images.Filetypes.generic.image
        }
    }
    
    @objc func image(for extension: String) -> UIImage {
        let ext = `extension`.lowercased()
        
        if ext.matches(regex: FileExtensionType.jpg.rawValue) {
            return Asset.Images.Filetypes.image.image
        } else {
            let fileTypesDictionary = Helper.fileTypesDictionary()
        
            guard let fileTypeImage = fileTypesDictionary[ext] as? String,
                  !fileTypeImage.isEmpty else {
                return Asset.Images.Filetypes.generic.image
            }
            
            return ImageAsset(name: "\(fileTypeImage)").image
        }
    }
    
    private func commonFolderImage(for node: MEGANode) -> UIImage {
        if node.isInShare() {
            return Asset.Images.Filetypes.folderIncoming.image
        } else if node.isOutShare() {
            return Asset.Images.Filetypes.folderOutgoing.image
        } else {
            return Asset.Images.Filetypes.folder.image
        }
    }
    
    private func backupDeviceIcon(for node: MEGANode) -> UIImage {
        guard node.deviceId != nil, let nodeName = node.name, !nodeName.isEmpty else { return commonFolderImage(for: node) }
        let nodeNameLowerCased = nodeName.lowercased()
        
        if nodeNameLowerCased.matches(regex: BackupDeviceType.win.rawValue) {
            return Asset.Images.Backup.win.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceType.linux.rawValue) {
            return Asset.Images.Backup.linux.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceType.mac.rawValue) {
            return Asset.Images.Backup.mac.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceType.drive.rawValue) {
            return Asset.Images.Backup.drive.image
        } else {
            return Asset.Images.Backup.pc.image
        }
    }
}

enum BackupDeviceType: String {
    case win = "win|desktop"
    case linux = "linux|debian|ubuntu|centos"
    case mac = "mac"
    case drive = "ext|drive"
}

enum FileExtensionType: String {
    case jpg = "jpg|jpeg"
}
