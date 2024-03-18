import Foundation

public struct NotificationEntity: Sendable {
    public let id: NotificationIDEntity
    public let title: String
    public let description: String
    public let imageName: String?
    public let imagePath: String?
    public let startDate: Date?
    public let endDate: Date?
    public let shouldShowBanner: Bool
    public let firstCallToAction: CallToAction?
    public let secondCallToAction: CallToAction?
    
    public struct CallToAction: Sendable {
        public let text: String
        public let link: URL?
        
        public init(text: String, link: URL?) {
            self.text = text
            self.link = link
        }
    }
    
    public init(
        id: NotificationIDEntity,
        title: String,
        description: String,
        imageName: String?,
        imagePath: String?,
        startDate: Date?,
        endDate: Date?,
        shouldShowBanner: Bool,
        firstCallToAction: CallToAction?,
        secondCallToAction: CallToAction?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.imagePath = imagePath
        self.startDate = startDate
        self.endDate = endDate
        self.shouldShowBanner = shouldShowBanner
        self.firstCallToAction = firstCallToAction
        self.secondCallToAction = secondCallToAction
    }
}

extension NotificationEntity: Equatable {
    public static func == (lhs: NotificationEntity, rhs: NotificationEntity) -> Bool {
        lhs.id == rhs.id
    }
}
