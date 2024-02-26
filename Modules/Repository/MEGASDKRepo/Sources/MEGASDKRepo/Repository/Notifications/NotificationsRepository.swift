import MEGADomain
import MEGASdk
import MEGASwift

public struct NotificationsRepository: NotificationsRepositoryProtocol {
    public static var newRepo: NotificationsRepository {
        NotificationsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchLastReadNotification() async throws -> NotificationIDEntity {
        try await withAsyncThrowingValue { completion in
            sdk.getLastReadNotification(with: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(NotificationIDEntity(request.number)))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func updateLastReadNotification(notificationId: NotificationIDEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.setLastReadNotificationWithNotificationId(notificationId, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func fetchEnabledNotifications() -> [NotificationIDEntity] {
        guard let enabledNotificationList = sdk.getEnabledNotifications() else { return []}
    
        return (0..<enabledNotificationList.size)
            .compactMap(NotificationIDEntity.init)
    }
}
