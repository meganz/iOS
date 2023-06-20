@objc final class RemovalConfirmationMessageGenerator: NSObject {
    @objc static func message(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String {
        precondition(fileCount > .zero || folderCount > .zero, "If both file and folder count are zero, no files/folders have been removed.  There is no need for an alert")
        return String.inject(plurals: [
            .init(count: fileCount, localize: Strings.Localizable.SharedItems.Rubbish.Confirmation.fileCount),
            .init(count: folderCount, localize: Strings.Localizable.SharedItems.Rubbish.Confirmation.folderCount)
        ], intoLocalized: Strings.Localizable.SharedItems.Rubbish.Confirmation.message)
    }
}
