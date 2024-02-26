public protocol NotificationsUseCaseProtocol {
    func fetchLastReadNotification() async throws -> NotificationIDEntity
    func updateLastReadNotification(notificationId: NotificationIDEntity) async throws
}

public struct NotificationsUseCase<T: NotificationsRepositoryProtocol>: NotificationsUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func fetchLastReadNotification() async throws -> UInt32 {
        try await repository.fetchLastReadNotification()
    }
    
    public func updateLastReadNotification(notificationId: NotificationIDEntity) async throws {
        try await repository.updateLastReadNotification(notificationId: notificationId)
    }
}
