import MEGAPresentation
import PhotosBrowser

extension RecentsViewController {
    @objc func photosBrowserViewController(with nodes: [MEGANode]) -> UIViewController? {
        guard let node = nodes.first else { return nil }
        
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .photosBrowser) {
            let config = PhotosBrowserConfiguration(displayMode: .cloudDrive,
                                                    library: MediaLibrary(assets: nodes.toPhotosBrowserEntities(), currentIndex: 0))
            let photoBrowserViewModel = PhotosBrowserViewModel(config: config)
            let photosBrowserViewController = PhotosBrowserViewController(viewModel: photoBrowserViewModel)
            photosBrowserViewController.modalPresentationStyle = .overFullScreen
            
            return photosBrowserViewController
        } else {
            return MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: NSMutableArray(array: nodes),
                                                               api: MEGASdk.shared,
                                                               displayMode: DisplayMode.cloudDrive,
                                                               isFromSharedItem: false, presenting: node)
        }
    }
}
