import MEGADomain
import MEGAL10n

extension DeviceCenterAction {
    static func infoAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .info,
            title: Strings.Localizable.info,
            icon: "info"
        )
    }
    
    static func offlineAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .offline,
            title: Strings.Localizable.General.downloadToOffline,
            icon: "offline"
        )
    }
    
    static func shareLinkAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .shareLink,
            title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
            icon: "link"
        )
    }
    
    static func manageLinkAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .manageLink,
            title: Strings.Localizable.General.MenuAction.ManageLink.title(1),
            icon: "link"
        )
    }
    
    static func removeLinkAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .removeLink,
            title: Strings.Localizable.General.MenuAction.RemoveLink.title(1),
            icon: "removeLink"
        )
    }

    static func shareFolderAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .shareFolder,
            title: Strings.Localizable.General.MenuAction.ShareFolder.title(1),
            icon: "shareFolder"
        )
    }
    
    static func manageFolderAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .manageShare,
            title: Strings.Localizable.manageShare,
            icon: "shareFolder"
        )
    }
    
    static func copyAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .copy,
            title: Strings.Localizable.copy,
            icon: "copy"
        )
    }
    
    static func showInCloudDriveAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .showInCloudDrive,
            title: Strings.Localizable.Device.Center.Show.In.Cloud.Drive.Action.title,
            icon: "cloudDriveFolder"
        )
    }
    
    static func favouriteAction(isFavourite: Bool) -> DeviceCenterAction {
        DeviceCenterAction(
            type: .favourite,
            title: isFavourite ? 
                Strings.Localizable.removeFavourite :
                Strings.Localizable.favourite,
            icon: isFavourite ?
                "removeFavourite" :
                "favourite"
        )
    }
    
    static func labelAction(label: NodeLabelTypeEntity) -> DeviceCenterAction {
        DeviceCenterAction(
            type: .label,
            title: Strings.Localizable.CloudDrive.Sort.label,
            dynamicSubtitle: label.stringForType,
            icon: "label",
            subActions: {
                NodeLabelTypeEntity.allCases.compactMap { labelType in
                    guard let actionType = labelType.deviceCenterActionType() else { return nil }
                    return DeviceCenterAction(
                        type: actionType,
                        title: labelType.stringForType(),
                        icon: labelType.iconName()
                    )
                }
            }()
        )
    }
    
    static func renameAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .rename,
            title: Strings.Localizable.rename,
            icon: "rename"
        )
    }
    
    static func moveAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .move,
            title: Strings.Localizable.move,
            icon: "move"
        )
    }
    
    static func moveToTheRubbishBinAction() -> DeviceCenterAction {
        DeviceCenterAction(
            type: .moveToTheRubbishBin,
            title: Strings.Localizable.General.MenuAction.moveToRubbishBin,
            icon: "rubbishBin"
        )
    }
}
