enum FolderLinkTitleType {
    // Begin editing
    case askForSelecting
    // Editing is inactive
    case folderNodeName(String)
    // While editing with some items selected
    case selectedItems(Int)
    // Folder link node is undecrypted
    case undecryptedFolder
    // Other cases: Folder Link
    case generic
}
