import MEGADomain

struct TextEditorModel: Equatable {
    let textFile: TextFile
    let textEditorMode: TextEditorMode
    var isEditable: Bool {
        textEditorMode == .create || textEditorMode == .edit
    }
    let accessLevel: NodeAccessTypeEntity?
    /// Last-read position for the editor to start at.
    /// On the plain text screen it is a character offset, not the scroll offset.
    /// On the Markdown screen it is the restore line: a 0-based source line.
    let resumeReadingOffset: Int?
    /// A link file under the link revamp, whose bar items take the link screens' Save to MEGA and Copy to Offline icons.
    var usesLinkRevampIcons = false
}

struct NavbarItemModel: Equatable {
    let title: String?
    let image: UIImage?
}
struct TextEditorNavbarItemsModel: Equatable {
    let leftItem: NavbarItemModel
    let rightItem: NavbarItemModel?
    let textEditorMode: TextEditorMode
}

struct TextEditorDuplicateNameAlertModel: Equatable {
    let alertTitle: String
    let alertMessage: String
    let cancelButtonTitle: String
    let replaceButtonTitle: String
    let renameButtonTitle: String
}

struct TextEditorRenameAlertModel: Equatable {
    let alertTitle: String
    let alertMessage: String
    let cancelButtonTitle: String
    let renameButtonTitle: String
    let textFileName: String
}
