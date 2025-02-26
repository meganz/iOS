import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

public struct NotificationSettingsRepository: NotificationSettingsRepositoryProtocol {
    public static var newRepo: NotificationSettingsRepository {
        NotificationSettingsRepository(sdk: .sharedSdk)
    }
    
    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func getPushNotificationSettings() async throws -> NotificationSettingsEntity {
        try await withAsyncThrowingValue { completion in
            sdk.getPushNotificationSettings(with: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let notificationSettings = request.megaPushNotificationSettings else {
                        completion(.failure(GenericErrorEntity()))
                        return
                    }
                    completion(.success(notificationSettings.toNotificationSettingsEntity()))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }
    
    public func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws -> NotificationSettingsEntity {
        try await withAsyncThrowingValue { completion in
            sdk.setPushNotificationSettings(settings.toMEGAPushNotificationSettings(), delegate: RequestDelegate { result in
                if case let .success(request) = result,
                   let settings = request.megaPushNotificationSettings {
                    completion(.success(settings.toNotificationSettingsEntity()))
                } else {
                    completion(.failure(GenericErrorEntity()))
                }
            })
        }
    }
}
