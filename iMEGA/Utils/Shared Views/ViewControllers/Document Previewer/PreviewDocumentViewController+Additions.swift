import MEGADomain

extension PreviewDocumentViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        return NodeInfoViewModel(withNode: node)
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: fileLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func showRemoveLinkWarning(_ node: MEGANode) {
        ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        }).start()
    }
}
