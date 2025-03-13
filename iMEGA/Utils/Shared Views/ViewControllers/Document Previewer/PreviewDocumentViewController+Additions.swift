import MEGAAnalyticsiOS
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

extension PreviewDocumentViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        return NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: fileLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func showRemoveLinkWarning(_ node: MEGANode) {
        let router = ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        })
        router.start()
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                      nodes: nodes).start()
    }
    
    @objc func setupTextView() -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        /// Disables non-contiguous layout for the `UITextView` to force a full text layout update.
        /// This helps resolve issues where the `UITextView` might become invisible or fail to render long text correctly.
        textView.layoutManager.allowsNonContiguousLayout = false
        
        textView.isEditable = false
        return textView
    }
    
    @objc func setupOpenZipButton() -> UIButton {
        let openZipButton = UIButton(type: .custom)
        
        openZipButton.translatesAutoresizingMaskIntoConstraints = false
        openZipButton.setTitle(Strings.Localizable.openButton, for: .normal)
        openZipButton.backgroundColor = TokenColors.Button.primary
        openZipButton.setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
        openZipButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        
        openZipButton.setupLayer()
        
        view.addSubview(openZipButton)
        
        let bottomInset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        
        NSLayoutConstraint.activate([
            openZipButton.widthAnchor.constraint(equalToConstant: 300),
            openZipButton.heightAnchor.constraint(equalToConstant: 60),
            openZipButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            openZipButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomInset)
        ])
        
        return openZipButton
    }
    
    @objc func hideNode(_ node: MEGANode) {
        DIContainer.tracker.trackAnalyticsEvent(with: DocumentPreviewHideNodeMenuItemEvent())
        HideFilesAndFoldersRouter(presenter: self)
            .hideNodes([node.toNodeEntity()])
    }
    
    @objc func unhideNode(_ node: MEGANode) {
        HideFilesAndFoldersRouter(presenter: self)
            .unhideNodes([node.toNodeEntity()])
    }
}

extension PreviewDocumentViewController: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNode = nodeList?.toNodeArray()
            .first(where: { $0.handle == node?.handle }) else { return }
        node = updatedNode
    }
}
