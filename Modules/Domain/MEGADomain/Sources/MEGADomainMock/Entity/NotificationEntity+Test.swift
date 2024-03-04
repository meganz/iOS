import Foundation
import MEGADomain

public extension NotificationEntity {
    init(
        id: NotificationIDEntity,
        title: String = "",
        description: String = "",
        imageName: String? = nil,
        imagePath: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        shouldShowBanner: Bool = false,
        firstCallToAction: CallToAction? = nil,
        secondCallToAction: CallToAction? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            id: id,
            title: title,
            description: description,
            imageName: imageName,
            imagePath: imagePath,
            startDate: startDate,
            endDate: endDate,
            shouldShowBanner: shouldShowBanner,
            firstCallToAction: firstCallToAction,
            secondCallToAction: secondCallToAction
        )
    }
}
