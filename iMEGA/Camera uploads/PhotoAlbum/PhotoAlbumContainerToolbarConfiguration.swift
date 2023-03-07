final class PhotoAlbumContainerToolbarConfiguration: ExplorerToolbarConfigurator {    
    init() {
        super.init(
            downloadAction: {_ in },
            shareLinkAction: {_ in },
            moveAction: {_ in },
            copyAction: {_ in },
            deleteAction: {_ in },
            moreAction: {_ in }
        )
    }
    
    override func buttonPressed(_ barButtonItem: UIBarButtonItem) { }
    
    override func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        let barButtonItems = [UIBarButtonItem]()

        return enable(nodes?.isNotEmpty == true, barButtonItems: barButtonItems)
    }
}
