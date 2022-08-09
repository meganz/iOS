
extension PreviewDocumentViewController {
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: fileLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
}
