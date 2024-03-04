import MEGASdk

public final class MockNotificationList: MEGANotificationList {
    
    public private(set) var notifications: [MEGANotification]
    
    public init(notifications: [MEGANotification] = []) {
        self.notifications = notifications
    }
    
    public override var size: Int { notifications.count }
    
    public override func notification(at index: Int) -> MEGANotification? {
        notifications[index]
    }
}
