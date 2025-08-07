import Foundation
import MEGAPreference

public protocol CameraUploadBackupReminderUseCaseProtocol: Sendable {
    func setupReminderNotification(_ setup: SetupCameraUploadReminderEntity) async throws
}

public struct CameraUploadBackupReminderUseCase: CameraUploadBackupReminderUseCaseProtocol {
    private let localNotificationRepository: any LocalNotificationRepositoryProtocol
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadEnabled: Bool
    
    public init(
        localNotificationRepository: some LocalNotificationRepositoryProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        self.localNotificationRepository = localNotificationRepository
        $isCameraUploadEnabled.useCase = preferenceUseCase
    }
    
    public func setupReminderNotification(_ setup: SetupCameraUploadReminderEntity) async throws {
        localNotificationRepository.cancelNotification(with: setup.notificationId)
        
        guard isCameraUploadEnabled else {
            throw SetupCameraUploadReminderErrorEntity.cameraUploadsNotEnabled
        }
        guard let notificationDate = reminderDate(afterDays: 28, atHour: 20) else {
            throw SetupCameraUploadReminderErrorEntity.invalidDate
        }
        
        try await localNotificationRepository
            .scheduleNotification(.init(
                date: notificationDate,
                id: setup.notificationId,
                title: setup.title,
                body: setup.body))
    }
    
    private func reminderDate(afterDays days: Int, atHour hour: Int, minute: Int = 0, second: Int = 0) -> Date? {
        let calendar = Calendar.current
        let baseDate = Date.now
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: baseDate) else { return nil }
        
        var components = calendar.dateComponents([.year, .month, .day], from: futureDate)
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return calendar.date(from: components)
    }
}
