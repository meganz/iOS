import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import UIKit

protocol BackgroundTaskExpirationNotifierProtocol: Sendable {
    func notify(for taskIdentifier: String, title: String)
}

@MainActor
protocol ApplicationStateProviderProtocol: Sendable {
    var applicationState: UIApplication.State { get }
}

struct ApplicationStateProvider: ApplicationStateProviderProtocol {
    var applicationState: UIApplication.State {
        UIApplication.shared.applicationState
    }
}

struct BackgroundTaskExpirationNotifier: BackgroundTaskExpirationNotifierProtocol {
    private let localNotificationRepository: any LocalNotificationRepositoryProtocol
    private let appStateProvider: any ApplicationStateProviderProtocol
    
    init(localNotificationRepository: some LocalNotificationRepositoryProtocol,
         appStateProvider: some ApplicationStateProviderProtocol = ApplicationStateProvider()) {
        self.localNotificationRepository = localNotificationRepository
        self.appStateProvider = appStateProvider
    }
    
    func notify(for taskIdentifier: String, title: String) {
        Task {
            do {
                let body = await expiredNotificationContent()
                let notificationEntity = LocalNotificationEntity(id: taskIdentifier, title: title, body: body)
                localNotificationRepository.cancelNotification(with: taskIdentifier)
                try await localNotificationRepository.scheduleNotification(notificationEntity)
            } catch {
                MEGALogError("[BGTask] \(taskIdentifier) Failed to schedule notification: \(error)")
            }
        }
    }
    
    @MainActor
    private func expiredNotificationContent() -> String {
        if appStateProvider.applicationState == .active {
            Strings.Localizable.Notification.Transfer.InProgress.message
        } else {
            Strings.Localizable.Notification.Transfer.Paused.message
        }
    }
}
