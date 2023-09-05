import MEGAL10n

@objc final class RemovalConfirmationMessageGenerator: NSObject {
    @objc static func message(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String {
        precondition(fileCount > .zero || folderCount > .zero, "If both file and folder count are zero, no files/folders have been removed.  There is no need for an alert")
        return Strings.Localizable.SharedItems.Rubbish.Confirmation.removedItemCount(fileCount + folderCount)
    }
}
