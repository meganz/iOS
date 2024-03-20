import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import UIKit

public final class NotificationItemViewModel: ObservableObject {
    let notification: NotificationItem
    private let imageLoader: ImageLoader
    @Published var imageBanner: UIImage?
    @Published var icon: UIImage?

    public init(
        notification: NotificationItem,
        imageLoader: ImageLoader
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
            return Strings.Localizable.Notifications.Expiration.message(
                notification.formattedExpirationDate,
                notification.formattedExpirationTime
            )
        default:
            return notification.formattedExpirationDate
        }
    }
    
    // It is not possible to show both the banner and the icon at the same time in our UI.
    // Therefore, we prioritize showing the banner over the icon if both elements are available.
    func preloadImages() async {
        if let bannerURL = notification.bannerImageURL {
            if let loadedImage = await imageLoader.loadImage(from: bannerURL) {
                await MainActor.run {
                    self.imageBanner = loadedImage
                }
                return
            }
        }
        
        if let iconURL = notification.iconURL {
            if let loadedImage = await imageLoader.loadImage(from: iconURL) {
                await MainActor.run {
                    self.icon = loadedImage
                }
            }
        }
    }
}
