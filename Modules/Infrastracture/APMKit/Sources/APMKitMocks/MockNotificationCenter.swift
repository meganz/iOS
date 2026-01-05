@testable import APMKit
import Foundation

final class MockNotificationCenter: NotificationCenterProtocol, @unchecked Sendable {
    private var observers: [(observer: AnyObject, selector: Selector, name: NSNotification.Name?)] = []
    
    func addObserver(_ observer: Any, selector: Selector, name: NSNotification.Name?, object: Any?) {
        observers.append((observer as AnyObject, selector, name))
    }
    
    func post(name: NSNotification.Name, object: Any?) {
        for entry in observers where entry.name == name {
            _ = entry.observer.perform(entry.selector)
        }
    }
    
    var observerCount: Int { observers.count }
}
