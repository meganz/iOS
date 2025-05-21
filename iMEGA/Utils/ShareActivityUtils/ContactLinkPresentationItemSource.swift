import LinkPresentation

class ContactLinkPresentationItemSource: NSObject, UIActivityItemSource {
    let linkMetaData: LPLinkMetadata
    
    init(title: String, description: String, icon: UIImage, url: URL) {
        let linkMetaData = LPLinkMetadata()
        linkMetaData.iconProvider = NSItemProvider(object: icon)
        linkMetaData.url = url
        linkMetaData.originalURL = URL(fileURLWithPath: description)
        linkMetaData.title = title
        self.linkMetaData = linkMetaData
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        linkMetaData
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let descriptionMessage = linkMetaData.originalURL?.relativeString.removingPercentEncoding, let urlPath = linkMetaData.url?.absoluteString {
            return descriptionMessage + " " + urlPath
        } else {
            return linkMetaData.url
        }
    }
}
