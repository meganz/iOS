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
    
    private func actionsForBackup(_ node: NodeEntity) -> [DeviceCenterAction] {
        var actions: [DeviceCenterAction] = [
            .downloadAction()
        ]
        
        if node.isExported {
            actions.append(contentsOf: [
                .manageLinkAction(),
                .removeLinkAction()
            ])
        } else {
            actions.append(.shareLinkAction())
        }
        
        if node.isOutShare {
            actions.append(.manageFolderAction())
        } else {
            actions.append(.shareFolderAction())
        }
        
        actions.append(.copyAction())
        
        return actions
    }
    
    private func actionsForCUBackup(_ node: NodeEntity) -> [DeviceCenterAction] {
        var actions: [DeviceCenterAction] = [
            .favouriteAction(isFavourite: node.isFavourite),
            .labelAction(label: node.label),
            .downloadAction()
        ]
        
        if node.isExported {
            actions.append(contentsOf: [
                .manageLinkAction(),
                .removeLinkAction()
            ])
        } else {
            actions.append(.shareLinkAction())
        }
        
        if node.isOutShare {
            actions.append(.manageFolderAction())
        } else {
            actions.append(.shareFolderAction())
        }
        
        actions.append(
            contentsOf: [
                .moveAction(),
                .copyAction(),
                .moveToTheRubbishBinAction()
            ]
        )
        return actions
    }
    
    private func actionsForSyncBackup(_ node: NodeEntity) -> [DeviceCenterAction] {
        var actions: [DeviceCenterAction] = [
            .favouriteAction(isFavourite: node.isFavourite),
            .labelAction(label: node.label),
            .downloadAction()
        ]
        
        if node.isExported {
            actions.append(contentsOf: [
                .manageLinkAction(),
                .removeLinkAction()
            ])
        } else {
            actions.append(.shareLinkAction())
        }
        
        if node.isOutShare {
            actions.append(.manageFolderAction())
        } else {
            actions.append(.shareFolderAction())
        }
        
        actions.append(
            contentsOf: [
                .moveAction(),
                .copyAction(),
                .moveToTheRubbishBinAction()
            ]
        )
        return actions
    }
    
    func actionsForBackup(_ backup: BackupEntity) -> [DeviceCenterAction] {
        guard let node else { return  [] }
        var actions = [DeviceCenterAction]()
        
        actions.append(.infoAction())
        
        if backup.type == .backupUpload {
            actions.append(contentsOf: actionsForBackup(node))
        } else if backup.type == .cameraUpload || backup.type == .mediaUpload {
            actions.append(contentsOf: actionsForCUBackup(node))
        } else if backup.type == .upSync || backup.type == .downSync || backup.type == .twoWay {
            actions.append(contentsOf: actionsForSyncBackup(node))
        }
        
        return actions
    }
    
    func actionsForDevices(_ device: DeviceEntity) -> [DeviceCenterAction] {
        []
    }
}
