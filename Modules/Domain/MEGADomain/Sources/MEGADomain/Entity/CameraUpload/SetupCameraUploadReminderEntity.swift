public struct SetupCameraUploadReminderEntity: Sendable {
    public let notificationId: String
    public let title: String
    public let body: String
    
    public init(
        notificationId: String,
        title: String,
        body: String
    ) {
        self.notificationId = notificationId
        self.title = title
        self.body = body
    }
}
