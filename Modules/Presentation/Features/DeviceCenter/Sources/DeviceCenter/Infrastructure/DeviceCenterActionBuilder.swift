import MEGADomain

final class DeviceCenterActionBuilder {
    private var type: DeviceCenterItemType = .unknown
    private var node: NodeEntity?

    func setActionType(_ type: DeviceCenterItemType) -> DeviceCenterActionBuilder {
        self.type = type
        return self
    }
    
    func setNode(_ node: NodeEntity) -> DeviceCenterActionBuilder {
        self.node = node
        return self
    }
    
    func build() -> [DeviceCenterAction] {
        switch type {
        case .backup(let backup):
            return actionsForBackup(backup)
        case .device(let device):
            return actionsForDevices(device)
        default:
            return []
        }
    }
    
    func actionsForBackup(_ backup: BackupEntity) -> [DeviceCenterAction] {
        guard let node else { return  [] }
        var actions = [DeviceCenterAction]()
        
        actions.append(.infoAction())
        
        if backup.type == .backupUpload {
            actions.append(.offlineAction())
            
            if node.isExported {
                actions.append(.manageLinkAction())
                actions.append(.removeLinkAction())
            } else {
                actions.append(.shareLinkAction())
            }
            
            
            if node.isOutShare {
                actions.append(.manageFolderAction())
            } else {
                actions.append(.shareFolderAction())
            }
            
            actions.append(.copyAction())
        } else if backup.type == .cameraUpload || backup.type == .mediaUpload {
            actions.append(DeviceCenterAction.showInCloudDriveAction())
        }
        
        return actions
    }
    
    func actionsForDevices(_ device: DeviceEntity) -> [DeviceCenterAction] {
        // Will be added in future tickets
        []
    }
}
