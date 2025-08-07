import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct CameraUploadBackupReminderUseCaseTests {

    private let setupNotification = SetupCameraUploadReminderEntity(
        notificationId: "id", title: "title", body: "body"
    )
    
    @Test func cameraUploadDisabled() async throws {
        let localNotificationRepository = MockLocalNotificationRepository()
        let sut = Self.makeSUT(
            localNotificationRepository: localNotificationRepository,
            preferenceUseCase: MockPreferenceUseCase(dict: [:]))
        
        await #expect(throws: SetupCameraUploadReminderErrorEntity.cameraUploadsNotEnabled) {
            try await sut.setupReminderNotification(setupNotification)
        }
        #expect(localNotificationRepository.actions == [.cancelNotification(id: setupNotification.notificationId)])
    }
    
    @Test("Ensure notification is setup in 28 days at 8pm")
    func scheduleNotification() async throws {
        let localNotificationRepository = MockLocalNotificationRepository()
        let sut = Self.makeSUT(
            localNotificationRepository: localNotificationRepository,
            preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]))
        
        try await sut.setupReminderNotification(setupNotification)
        
        let calendar = Calendar.current
        let today = Date.now
        let twentyEightDaysLater = try #require(calendar.date(byAdding: .day, value: 28, to: today))
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: twentyEightDaysLater)
        dateComponents.hour = 20
        dateComponents.minute = 0
        dateComponents.second = 0
        
        #expect(localNotificationRepository.actions == [
            .cancelNotification(id: setupNotification.notificationId),
            .scheduleNotification(.init(
                date: try #require(calendar.date(from: dateComponents)),
                id: setupNotification.notificationId,
                title: setupNotification.title,
                body: setupNotification.body))
        ])
    }

    private static func makeSUT(
        localNotificationRepository: some LocalNotificationRepositoryProtocol = MockLocalNotificationRepository(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [:])
    ) -> CameraUploadBackupReminderUseCase {
        .init(
            localNotificationRepository: localNotificationRepository,
            preferenceUseCase: preferenceUseCase)
    }
}
