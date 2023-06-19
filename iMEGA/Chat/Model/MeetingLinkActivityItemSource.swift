import LinkPresentation
import MobileCoreServices

class MeetingLinkPresentationItemSource: NSObject, UIActivityItemSource {
    private let metadata: LPLinkMetadata
    
    @objc init(url: URL, title: String) {
        let metadata = LPLinkMetadata()
        metadata.url = url
        metadata.title = title
        self.metadata = metadata
        super.init()
        fetchUrlThumbnail(url)
    }
        
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return metadata.url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
    
    // MARK: - Private
    
    private func fetchUrlThumbnail(_ url: URL) {
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            guard error == nil else { return }
            metadata?.imageProvider?.loadObject(ofClass: UIImage.self, completionHandler: { image, error in
                guard error == nil, let image = image as? UIImage else { return }
                asyncOnMain {
                    self.metadata.imageProvider = NSItemProvider(object: image)
                }
            })
        }
    }
}
