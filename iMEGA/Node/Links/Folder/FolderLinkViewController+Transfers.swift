extension FolderLinkViewController {
    @objc func download(_ nodes: [MEGANode]) {
        DownloadLinkRouter(nodes: nodes.toNodeEntities(), isFolderLink: true, presenter: self).start()
    }
}
