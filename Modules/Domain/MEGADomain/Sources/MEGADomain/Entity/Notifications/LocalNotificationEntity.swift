import Foundation

/// A sendable entity representing a local notification.
///
/// `LocalNotificationEntity` encapsulates all the information needed to schedule
/// a local notification, including its timing, content, and metadata.
public struct LocalNotificationEntity: Sendable {
    /// The date and time when the notification should be delivered.
    ///
    /// If `nil`, the notification will be delivered immediately when scheduled.
    /// When `repeats` is `true`, this date determines the first delivery time
    /// and the recurrence pattern.
    public let date: Date?
    
    /// A unique identifier for the notification.
    ///
    /// This identifier is used to update or remove the notification before it's delivered.
    /// If you schedule a notification with the same identifier as an existing one,
    /// the existing notification will be replaced.
    public let id: String
    
    /// The title text displayed in the notification.
    ///
    /// This appears as the main heading of the notification and should be brief and descriptive.
    public let title: String
    
    /// The body text displayed in the notification.
    ///
    /// This provides additional details about the notification and can be longer than the title.
    public let body: String
    
    /// A Boolean value indicating whether the notification repeats.
    ///
    /// When `true`, the notification will be delivered repeatedly based on the
    /// date components. When `false`, the notification is delivered only once.
    public let repeats: Bool
    
    /// Additional custom data to associate with the notification.
    ///
    /// This dictionary allows you to pass custom information that can be accessed
    /// when the user interacts with the notification. All values must conform to `Sendable`.
    public let userInfo: [String: any Sendable]
    
    /// Creates a new local notification entity.
    ///
    /// - Parameters:
    ///   - date: The date and time when the notification should be delivered.
    ///           If `nil`, the notification will be delivered immediately. Defaults to `nil`.
    ///   - id: A unique identifier for the notification. Used to update or cancel the notification.
    ///   - title: The title text displayed in the notification.
    ///   - body: The body text displayed in the notification.
    ///   - repeats: Whether the notification should repeat. Defaults to `false`.
    ///   - userInfo: Additional custom data to associate with the notification. Defaults to an empty dictionary.
    public init(
        date: Date? = nil,
        id: String,
        title: String,
        body: String,
        repeats: Bool = false,
        userInfo: [String: any Sendable] = [:]
    ) {
        self.date = date
        self.id = id
        self.title = title
        self.body = body
        self.repeats = repeats
        self.userInfo = userInfo
    }
}
