import Foundation
import MEGAL10n
import MEGASwiftUI
import MEGASwiftUIMock
@testable import Notifications
import NotificationsMocks
import Testing
import UIKit

@Suite("NotificationItemViewModelTests")
struct NotificationItemViewModelTests {
    
    @MainActor
    private static func makeSUT(
        notification: NotificationItem = NotificationItem(),
        imageLoader: any ImageLoadingProtocol = MockImageLoader()
    ) -> NotificationItemViewModel {
        NotificationItemViewModel(notification: notification, imageLoader: imageLoader)
    }
    
    @MainActor
    @Suite("Banner and Icon images")
    struct NotificationImages {
        private func expectedResult(name: String?, path: String?) -> Bool {
            name != nil && name != "" && path != nil
        }
        
        @Test(
            "HasBannerImage should return true only if notification has imageName and imagePath",
            arguments: ["Test banner name", "", nil], ["https://mega.nz/banner", nil]
        )
        func hasBannerImage(imageName: String?, imagePath: String?) {
            let sut = makeSUT(
                notification: NotificationItem(
                    imageName: imageName,
                    imagePath: imagePath
                )
            )
            
            #expect(sut.hasBannerImage == expectedResult(name: imageName, path: imagePath))
        }
        
        @Test(
            "HasIcon should return true only if notification has iconName and imagePath",
            arguments: ["Test icon name", "", nil], ["https://mega.nz/icon", nil]
        )
        func hasIcon(iconName: String?, imagePath: String?) {
            let sut = makeSUT(
                notification: NotificationItem(
                    imagePath: imagePath,
                    iconName: iconName
                )
            )
            
            #expect(sut.hasIcon == expectedResult(name: iconName, path: imagePath))
        }
    }
    
    @MainActor
    @Suite("Footer text")
    struct NotificationFooterText {
        @Test("Return correct footerText if notification endDate has value")
        func footerTextForPromoWithEndDate() throws {
            let notification = NotificationItem(endDate: Date())
            let sut = makeSUT(notification: notification)
            let expectedString = Strings.Localizable.Notifications.Expiration.message
                .replacingOccurrences(of: "[date]", with: notification.formattedExpirationDate)
                .replacingOccurrences(of: "[time]", with: notification.formattedExpirationTime)
            
            #expect(sut.footerText() == expectedString)
        }
        
        @Test("Return nil footerText if notification endDate is nil")
        func footerTextForPromoWithNoEndDate() {
            let sut = makeSUT(notification: NotificationItem(endDate: nil))
            #expect(sut.footerText() == nil)
        }
    }
    
    @MainActor
    @Suite("Preload images")
    struct NotificationPreloadImages {
        private let defaultImage = UIImage(systemName: "photo")
        
        @Test("Load banner image if existing")
        func loadBannerImage() async {
            let sut = makeSUT(
                notification: NotificationItem(
                    imageName: "Test banner name",
                    imagePath: "https://mega.nz/banner"
                ),
                imageLoader: MockImageLoader(image: defaultImage)
            )
            
            await sut.preloadImages()
            #expect(sut.imageBanner == defaultImage)
        }
        
        @Test("Only load the banner image even if icon is available")
        func loadBannerImageAndIgnoreIcon() async {
            let sut = makeSUT(
                notification: NotificationItem(
                    imageName: "Test banner name",
                    imagePath: "https://mega.nz/banner", 
                    iconName: "Test icon name"
                ),
                imageLoader: MockImageLoader(image: defaultImage)
            )
            
            await sut.preloadImages()
            #expect(sut.imageBanner == defaultImage)
        }
        
        @Test("Load icon image if existing and there's no banner available")
        func loadIconImage() async {
            let sut = makeSUT(
                notification: NotificationItem(
                    imagePath: "https://mega.nz/banner", 
                    iconName: "Test icon name"
                ),
                imageLoader: MockImageLoader(image: defaultImage)
            )
            
            await sut.preloadImages()
            #expect(sut.icon == defaultImage)
        }
    }
}
