extension MEGANode {
    // MARK: - Import
    @MainActor
    func openBrowserToImport(in viewController: UIViewController) {
        ImportLinkRouter(
            isFolderLink: false,
            nodes: [self],
            presenter: viewController).start()
    }
}
