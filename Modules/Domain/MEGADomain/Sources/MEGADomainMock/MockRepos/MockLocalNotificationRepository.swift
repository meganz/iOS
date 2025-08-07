import MEGADomain
import MEGASwift

public final class MockLocalNotificationRepository:
    LocalNotificationRepositoryProtocol,
    @unchecked Sendable {
    
    public enum Action {
        case scheduleNotification(LocalNotificationEntity)
        case cancelNotification(id: String)
    }
    @Atomic public var actions = [Action]()
    
    public init() {}
    
    public func scheduleNotification(_ notification: LocalNotificationEntity) async throws {
        add(action: .scheduleNotification(notification))
    }
    
    public func cancelNotification(with id: String) {
        add(action: .cancelNotification(id: id))
    }
    
    private func add(action: Action) {
        $actions.mutate { $0.append(action) }
    }
}

extension MockLocalNotificationRepository.Action: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.scheduleNotification(let lhsValue), .scheduleNotification(let rhsValue)):
            lhsValue.id == rhsValue.id && lhsValue.date == rhsValue.date &&
            lhsValue.title == rhsValue.title && lhsValue.body == rhsValue.body 
        case (.cancelNotification(let lhsValue), .cancelNotification(let rhsValue)):
            lhsValue == rhsValue
        default: false
        }
    }
}
