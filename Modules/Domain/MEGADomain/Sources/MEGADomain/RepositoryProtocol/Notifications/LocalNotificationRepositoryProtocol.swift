import Foundation

public protocol LocalNotificationRepositoryProtocol: Sendable {
    func scheduleNotification(_ notification: LocalNotificationEntity) async throws
    func cancelNotification(with id: String)
}
