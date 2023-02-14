import MEGADomain

extension PreviewDocumentViewController {
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        return NodeInfoViewModel(withNode: node)
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: fileLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
}
