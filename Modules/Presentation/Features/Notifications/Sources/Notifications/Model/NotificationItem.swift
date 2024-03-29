import Foundation
import MEGAFoundation

public typealias DateFormatterClosure = @Sendable (Date) -> String
/// NotificationID: A type alias for the unique identifier of a notification, represented as a `UInt32`. This makes it
/// clear that notification IDs are numeric and have a limited range. Defined to avoid dependency on the domain module,
/// data of this type will be mapped in the conversion from NotificationEntity (Domain) to NotificationItem (Presentation).
public typealias NotificationID =  UInt32

/// `NotificationItem`: It encapsulates all necessary details required for managing and displaying notifications to the user.
public struct NotificationItem {
    /// `id`: Unique identifier for the notification
    let id: NotificationID
    /// `title`: The main text to be displayed in the notification, serving as a brief summary about the notification's content
    let title: String
    /// `description`: Detailed information about the notification, providing the user with context or further details
    /// regarding the notification content.
    let description: String
    /// `imageName`: An optional string representing the name of the image to be displayed within the notification. This property
    /// can be used in conjunction with `imagePath` to construct URLs for loading images from a remote source.
    let imageName: String?
    /// `imagePath`: An optional string representing the path or URL base where the notification's image is located. This is used
    /// together with `imageName` to construct the complete URL to the image resource.
    let imagePath: String?
    /// `startDate`: An optional date indicating when the notification becomes relevant or should start being displayed to
    /// the user.
    let startDate: Date?
    /// `endDate`: An optional date indicating when the notification is no longer relevant and can be considered expired.
    let endDate: Date?
    /// `formatDateClosure`: A closure that provides a mechanism for custom formatting of date fields within the notification.
    /// This allows for flexible display of dates according to different locale settings and user preferences.
    private let formatDateClosure: DateFormatterClosure
    /// `formatTimeClosure`: A closure that provides a mechanism for custom formatting of date fields within the notification.
    /// This allows for flexible display of times according to different locale settings and user preferences.
    private let formatTimeClosure: DateFormatterClosure
    /// `formattedExpirationDate`: A computed property that uses `formatDateClosure` to generate a user-friendly string
    /// representation of the `endDate`, facilitating clear communication of when the notification will expire.
    var formattedExpirationDate: String {
        guard let endDate = endDate else { return "" }
        return formatDateClosure(endDate)
    }
    /// `formattedExpirationTime`: Computed property that uses `formatTimeClosure` for a user-friendly string of `endDate`.
    var formattedExpirationTime: String {
        guard let endDate = endDate else { return "" }
        return formatTimeClosure(endDate)
    }
    /// `tag`: A categorization tag for the notification, initially set to `.promo`. This system allows for the implementation
    /// of additional tags in the future, aiding in the organization and filtering of notifications.
    var tag: NotificationTag {
        .promo // Default value, more tags will be added in the future.
    }
    /// `type`: The type of notification, initially set to `.limitedTypeOffer`. This classification helps in distinguishing
    /// between different kinds of notifications, enabling tailored handling and presentation based on the notification type.
    var type: NotificationType {
        .limitedTypeOffer // Default value, more types will be added in the future.
    }
    /// `bannerImageURL`: A computed property that dynamically constructs a URL for the notification's banner image by combining
    /// `imagePath` and `imageName`. This URL can be used to load and display the image within the notification. If either
    /// `imageName` or `imagePath` is nil, this property will return nil, indicating that no banner image is available for the
    /// notification.
    var bannerImageURL: URL? {
        guard let imagePath, let imageName else { return nil }
        return URL(string: imagePath + imageName)
    }
    
    public init(
        id: NotificationID,
        title: String,
        description: String,
        imageName: String?,
        imagePath: String?,
        startDate: Date?,
        endDate: Date?,
        formatDateClosure: @escaping DateFormatterClosure = { DateFormatter.dateLong().localisedString(from: $0) },
        formatTimeClosure: @escaping DateFormatterClosure = {
            DateFormatter.timeShort().localisedString(from: $0) }
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.imagePath = imagePath
        self.startDate = startDate
        self.endDate = endDate
        self.formatDateClosure = formatDateClosure
        self.formatTimeClosure = formatTimeClosure
    }
}
