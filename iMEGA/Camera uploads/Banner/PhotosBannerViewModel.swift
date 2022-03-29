@objc final class PhotosBannerViewModel: NSObject, ObservableObject {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}
