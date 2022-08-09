
final class ActionViewModel: ObservableObject {
    
    let actionItem: NameCollisionAction
    
    init(actionItem: NameCollisionAction) {
        self.actionItem = actionItem
    }
    
    var showItemView: Bool {
        actionItem.isFile && (actionItem.name != nil)
    }
    
    var itemName: String {
        actionItem.name ?? ""
    }
    
    var actionTitle: String {
        switch actionItem.actionType {
        case .update:
            return Strings.Localizable.NameCollision.Files.Action.Update.title
        case .replace:
            return Strings.Localizable.NameCollision.Files.Action.Replace.title
        case .rename:
            return Strings.Localizable.NameCollision.Files.Action.Rename.title
        case .merge:
            return Strings.Localizable.NameCollision.Folders.Action.Merge.title
        case .cancel:
            return actionItem.isFile ? Strings.Localizable.NameCollision.Files.Action.Skip.title : Strings.Localizable.NameCollision.Folders.Action.Skip.title
        }
    }
    
    var actionDescription: String? {
        switch actionItem.actionType {
        case .update:
            return Strings.Localizable.NameCollision.Files.Action.Update.description
        case .replace:
            return Strings.Localizable.NameCollision.Files.Action.Replace.description
        case .rename:
            return Strings.Localizable.NameCollision.Files.Action.Rename.description
        case .merge:
            return Strings.Localizable.NameCollision.Folders.Action.Merge.description
        case .cancel:
            return nil
        }
    }
}
