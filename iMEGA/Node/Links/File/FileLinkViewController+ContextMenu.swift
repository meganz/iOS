import MEGADomain
import MEGASDKRepo

extension FileLinkViewController: FileLinkContextMenuDelegate {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        guard let node else { return nil }

        let isBackupNode = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ).isBackupNode(node.toNodeEntity())

        return CMConfigEntity(
            menuType: .menu(type: .fileLink),
            isRestorable: isBackupNode ? false : node.mnz_isRestorable(),
            isMediaFile: node.toNodeEntity().mediaType != nil
        )
    }

    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            quickActionsMenuDelegate: self,
            uploadAddMenuDelegate: self,
            rubbishBinMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
        setMoreButton()
    }

    private func setMoreButton() {
        guard let config = contextMenuConfiguration() else { return }
        moreBarButtonItem?.menu = contextMenuManager?.contextMenu(with: config)
    }

    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .shareLink:
            showShareLink()
        case .download:
            download()
        case .sendToChat:
            showSendToChat()
        default:
            break
        }
    }

    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        switch action {
        case .importFrom:
            importFromFiles()
        case .importFolderLink:
            addToCloudDrive()
        default:
            break
        }
    }

    func rubbishBinMenu(didSelect action: RubbishBinActionEntity) {
        switch action {
        case .restore:
            node?.mnz_restore()
            navigationController?.dismiss(animated: true)
        default:
            break
        }
    }
}
