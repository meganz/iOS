
extension FileLinkViewController {
    @objc func download() {
        guard let linkUrl = URL(string: publicLinkString) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
}
