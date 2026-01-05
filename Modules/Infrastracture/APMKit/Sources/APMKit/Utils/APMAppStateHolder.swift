import Foundation
import MEGASwift
import UIKit

protocol APMAppStateHolding: Sendable {
    var isInForeground: Bool { get }
}

protocol NotificationCenterProtocol: Sendable {
    func addObserver(_ observer: Any, selector: Selector, name: NSNotification.Name?, object: Any?)
    func post(name: NSNotification.Name, object: Any?)
}

extension NotificationCenter: NotificationCenterProtocol {}

final class APMAppStateHolder: APMAppStateHolding {
    private let notificationCenter: NotificationCenterProtocol
    private let isActive: Atomic<Bool> = .init(wrappedValue: true)
    var isInForeground: Bool {
        return isActive.wrappedValue
    }
    
    init(notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        setup()
    }
    
    private func setup() {
        Task { @MainActor in
            isActive.mutate { $0 = UIApplication.shared.applicationState == .active }
        }
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        isActive.mutate { $0 = false }
    }
    
    @objc private func appDidBecomeActive() {
        isActive.mutate { $0 = true }
    }
}
