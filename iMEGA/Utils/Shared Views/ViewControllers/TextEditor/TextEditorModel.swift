import MEGADomain

struct TextEditorModel: Equatable {
    let textFile: TextFile
    let textEditorMode: TextEditorMode
    var isEditable: Bool {
        textEditorMode == .create || textEditorMode == .edit
    }
    let accessLevel: NodeAccessTypeEntity?
    /// Last-read position for the editor to start at. Note: This is character offset, not the scroll content offset. 
    let resumeReadingOffset: Int?
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
