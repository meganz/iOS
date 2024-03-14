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
                    let notifError: NotificationErrorEntity = error.type == .apiENoent ? .noLastReadNotification : .generic
                    completion(.failure(notifError))
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
        return enabledNotificationList.toNotificationIDEntities()
    }
    
    public func fetchNotifications() async throws -> [NotificationEntity] {
        try await withAsyncThrowingValue { completion in
            sdk.getNotificationsWith(RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaNotifications?.toNotificationEntities() ?? []))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func unreadNotificationIDs() async -> [NotificationIDEntity] {
        let enabledNotificationIDs = fetchEnabledNotifications()
        do {
            let lastReadNotificationID = try await fetchLastReadNotification()
            
            guard lastReadNotificationID != 0 else {
                // Value `0` is an invalid ID. Receiving `0` means that the previously set last read value was cleared.
                return enabledNotificationIDs
            }
            
            return enabledNotificationIDs.filter {$0 > lastReadNotificationID}
        } catch {
            guard let error = error as? NotificationErrorEntity, error == .noLastReadNotification else {
                return []
            }
            // No last read notification yet. Return all enabled notif IDs.
            return enabledNotificationIDs
        }
    }
}
