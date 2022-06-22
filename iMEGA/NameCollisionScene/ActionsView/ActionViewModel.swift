
final class ActionViewModel: ObservableObject {
    private let collisionType: NameCollisionType
    
    let actionItem: NameCollisionAction
    
    init(collisionType: NameCollisionType, actionItem: NameCollisionAction) {
        self.collisionType = collisionType
        self.actionItem = actionItem
    }
    
    var showItemView: Bool {
        actionItem.isFile && (actionItem.name != nil)
    }
    
    var itemName: String {
        actionItem.name ?? ""
    }
    
    var actionTitle: String {
        switch collisionType {
        case .upload:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Upload.updateTitle
            case .replace:
                return Strings.Localizable.NameCollision.Files.Upload.replaceTitle
            case .rename:
                return Strings.Localizable.NameCollision.Files.Upload.renameTitle
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Upload.mergeTitle
            case .cancel:
                return Strings.Localizable.NameCollision.General.cancelTitle
            }
        case .move:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Move.replaceTitle
            case .replace:
                return Strings.Localizable.NameCollision.Files.Move.replaceTitle
            case .rename:
                return Strings.Localizable.NameCollision.Files.Move.renameTitle
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Move.mergeTitle
            case .cancel:
                return Strings.Localizable.NameCollision.General.dontMove
            }
        case .copy:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Copy.replaceTitle
            case .replace:
                return Strings.Localizable.NameCollision.Files.Copy.replaceTitle
            case .rename:
                return Strings.Localizable.NameCollision.Files.Copy.renameTitle
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Copy.mergeTitle
            case .cancel:
                return Strings.Localizable.NameCollision.General.dontCopy
            }
        }
        
    }
    
    var actionDescription: String {
        switch collisionType {
        case .upload:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Upload.updateDescription
            case .replace:
                return Strings.Localizable.NameCollision.Files.Upload.replaceDescription
            case .rename:
                return Strings.Localizable.NameCollision.Files.Upload.renameDescription
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Upload.mergeDescription
            case .cancel:
                if actionItem.isFile {
                    return Strings.Localizable.NameCollision.Files.cancelDescription
                } else {
                    return Strings.Localizable.NameCollision.Folders.cancelDescription
                }
            }
        case .move:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Move.replaceDescription
            case .replace:
                return Strings.Localizable.NameCollision.Files.Move.replaceDescription
            case .rename:
                return Strings.Localizable.NameCollision.Files.Move.renameDescription
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Move.mergeDescription
            case .cancel:
                if actionItem.isFile {
                    return Strings.Localizable.NameCollision.Files.cancelDescription
                } else {
                    return Strings.Localizable.NameCollision.Folders.cancelDescription
                }
            }
        case .copy:
            switch actionItem.actionType {
            case .update:
                return Strings.Localizable.NameCollision.Files.Copy.replaceDescription
            case .replace:
                return Strings.Localizable.NameCollision.Files.Copy.replaceDescription
            case .rename:
                return Strings.Localizable.NameCollision.Files.Copy.renameDescription
            case .merge:
                return Strings.Localizable.NameCollision.Folders.Copy.mergeDescription
            case .cancel:
                if actionItem.isFile {
                    return Strings.Localizable.NameCollision.Files.cancelDescription
                } else {
                    return Strings.Localizable.NameCollision.Folders.cancelDescription
                }
            }
        }
    }
}
