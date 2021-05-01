struct TextEditorModel: Equatable {
    let leftButtonTitle: String
    let rightButtonTitle: String?
    let textFile: TextFile
    let textEditorMode: TextEditorMode
    let accessLevel: NodeAccessTypeEntity?
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
