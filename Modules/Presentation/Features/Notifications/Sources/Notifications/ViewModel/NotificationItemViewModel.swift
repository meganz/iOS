import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import UIKit

@MainActor
public final class NotificationItemViewModel: ObservableObject {
    let notification: NotificationItem
    private let imageLoader: any ImageLoadingProtocol
    // Assign a transparent image to `imageBanner` and `icon` to prevent layout shifts
    // or flickers as images load. These placeholders maintain the UI's structure for a
    // smooth visual transition until the actual images are displayed.
    @Published var imageBanner: UIImage = UIImage.transparent
    @Published var icon: UIImage = UIImage.transparent
    
    var hasBannerImage: Bool {
        notification.bannerImageURL != nil
    }
    
    var hasIcon: Bool {
        notification.iconURL != nil
    }
    
    public init(
        notification: NotificationItem,
        imageLoader: some ImageLoadingProtocol
    ) {
        self.notification = notification
        self.imageLoader = imageLoader
    }
    
    func footerText() -> String? {
        switch notification.tag {
        case .promo:
            guard notification.formattedExpirationDate.isNotEmpty else {
                return nil
            }
            return Strings.Localizable.Notifications.Expiration.message
                .replacingOccurrences(of: "[date]", with: notification.formattedExpirationDate)
                .replacingOccurrences(of: "[time]", with: notification.formattedExpirationTime)
        default:
            return notification.formattedExpirationDate
        }
    }
    
    // It is not possible to show both the banner and the icon at the same time in our UI.
    // Therefore, if both elements are available, the UI prioritizes displaying the banner over
    // the icon due to design constraints.
    func preloadImages() async {
        if let bannerURL = notification.bannerImageURL,
           let loadedBanner = await imageLoader.loadImage(from: bannerURL) {
            imageBanner = loadedBanner
            return
        }
        
        if let iconURL = notification.iconURL,
           let loadedImage = await imageLoader.loadImage(from: iconURL) {
            icon = loadedImage
            return
        }
    }
}
