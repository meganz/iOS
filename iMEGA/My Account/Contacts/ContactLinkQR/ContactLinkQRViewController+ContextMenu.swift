import MEGADomain

extension ContactLinkQRViewController: QRMenuDelegate {
    private func contextMenuConfiguration() -> CMConfigEntity {
        CMConfigEntity(menuType: .menu(type: .qr),
                       isShareAvailable:!(contactLinkLabel?.text?.isEmpty ?? true))
    }
    
    @objc func setMoreButtonAction() {
        if #available(iOS 14.0, *) {
            moreButton?.menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration())
            moreButton?.showsMenuAsPrimaryAction = true
        } else {
            moreButton?.addTarget(self, action: #selector(presentActionSheet(sender:)), for: .touchUpInside)
        }
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(qrMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: contextMenuConfiguration()) else { return }
        presentActionSheet(actions: actions)
    }
    
    @objc func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)

        self.present(actionSheetVC, animated: true)
    }
    
    //MARK: - QRMenuDelegate functions
    func qrMenu(didSelect action: MyQRActionEntity) {
        switch action {
        case .share:
            let activityVC = UIActivityViewController(activityItems: [contactLinkLabel?.text ?? ""], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            if let frame = moreButton?.frame {
                activityVC.popoverPresentationController?.sourceRect = frame
            }
            
            present(activityVC, animated: true)
        case .settings:
            let navigationController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "QRSettingsNavigationControllerID")
            present(navigationController, animated: true)
        case .resetQR:
            self.qrImageView?.image = nil
            MEGASdkManager.sharedMEGASdk().contactLinkCreateRenew(true, delegate: contactLinkCreateDelegate)
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
