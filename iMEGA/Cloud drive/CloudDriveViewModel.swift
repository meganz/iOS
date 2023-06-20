import MEGADomain

@objc final class CloudDriveViewModel: NSObject {
    private let router = SharedItemsViewRouter()
    private let shareUseCase: (any ShareUseCaseProtocol)?
    
    init(shareUseCase: any ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }
    
    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task { @MainActor [shareUseCase] in
            do {
                _ = try await shareUseCase?.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @objc func alertMessage(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String {
        precondition(fileCount > .zero || folderCount > .zero, "If both file and folder count are zero, no files/folders are to be removed.  There is no need for an alert")
        return String.inject(plurals: [
            .init(count: fileCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.fileCount),
            .init(count: folderCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.folderCount)
        ], intoLocalized: Strings.Localizable.SharedItems.Rubbish.Warning.message)
    }
    
    @objc func alertTitle(forRemovedFiles fileCount: Int, andFolders folderCount: Int) -> String? {
        precondition(fileCount > .zero || folderCount > .zero, "If both file and folder count are zero, no files/folders are to be removed.  There is no need for an alert")
        guard fileCount > 1 else { return nil }
        return Strings.Localizable.removeNodeFromRubbishBinTitle
    }
}
