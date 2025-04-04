@preconcurrency import Combine
import Foundation
import MEGASwift

public struct CacheInvalidationTrigger: Sendable {
    
    enum Event {
        /// Event for when a logout of application has been triggered
        case logout
        /// Event for when the OS has triggered a Memory Warning event to application
        case applicationMemoryWarning
    }
    
    private let notificationCentre: NotificationCenter
    private let logoutNotificationName: Notification.Name
    private let didReceiveMemoryWarningNotificationName: @Sendable () async -> Notification.Name
        
    public init(
        notificationCentre: NotificationCenter = .default,
        logoutNotificationName: Notification.Name,
        didReceiveMemoryWarningNotificationName: @escaping @Sendable () async -> Notification.Name
    ) {
        self.notificationCentre = notificationCentre
        self.logoutNotificationName = logoutNotificationName
        self.didReceiveMemoryWarningNotificationName = didReceiveMemoryWarningNotificationName
    }
    
    /// Provides an AnyAsyncSequence that emits an InvalidationEvent, when any of the conditions are triggered.
    ///
    /// Supported triggers include:
    ///   - User session has been logout
    ///   - OS has triggered a memory warning to application
    /// - Returns: AnyAsyncSequence<InvalidationEvent>
    func cacheInvalidationSequence() async -> AnyAsyncSequence<Event> {
        Publishers.Merge(
            notificationCentre.publisher(for: logoutNotificationName)
                .map { _ in .logout },
            await notificationCentre.publisher(for: didReceiveMemoryWarningNotificationName())
                .map { _ in .applicationMemoryWarning })
            .values
            .eraseToAnyAsyncSequence()
    }
}
