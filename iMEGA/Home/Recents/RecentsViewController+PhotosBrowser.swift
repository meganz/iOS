import MEGAPresentation
import PhotosBrowser

extension RecentsViewController {
    @objc func photosBrowserViewController(with nodes: [MEGANode]) -> UIViewController? {
        guard let node = nodes.first else { return nil }
        
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .photosBrowser) {
            let images: [UIImage] = [UIImage.thumbnailsThin, UIImage(systemName: "play.rectangle"), UIImage.export].compactMap { $0 }
            let config = PhotosBrowserConfiguration(displayMode: .recents, toolbarImages: images)
            let photoBrowserViewModel = PhotosBrowserViewModel(config: config)
            let photosBrowserViewController = PhotosBrowserViewController(viewModel: photoBrowserViewModel)
            
            return photosBrowserViewController
        } else {
            return MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: NSMutableArray(array: nodes),
                                                               api: MEGASdk.shared,
                                                               displayMode: DisplayMode.cloudDrive,
                                                               isFromSharedItem: false, presenting: node)
        }
    }
}
