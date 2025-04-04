import MEGAAppSDKRepo
import MEGADomain

extension ContactLinkQRViewController: QRMenuDelegate {
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .qr),
                       isShareAvailable: !(contactLinkLabel?.text?.isEmpty ?? true))
    }
    
    @objc func setMoreButtonAction() {
        moreButton?.menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration())
        moreButton?.showsMenuAsPrimaryAction = true
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(qrMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    }
    
    // MARK: - QRMenuDelegate functions
    func qrMenu(didSelect action: MyQRActionEntity) {
        switch action {
        case .share:
            let activityVC = UIActivityViewController(activityItems: [contactLinkLabel?.text ?? ""], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            if let frame = moreButton?.frame {
                activityVC.popoverPresentationController?.sourceRect = frame
            }
            
            present(activityVC, animated: true)
        case .qrSettings:
            let navigationController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "QRSettingsNavigationControllerID")
            present(navigationController, animated: true)
        case .resetQR:
            self.qrImageView?.image = nil
            MEGASdk.shared.contactLinkCreateRenew(true, delegate: contactLinkCreateDelegate)
        }
    }
}
