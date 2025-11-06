import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

@MainActor
public final class NotificationSettingsViewModel: ObservableObject {
    private let notificationSettingsUseCase: any NotificationSettingsUseCaseProtocol
    
    var notificationSettings = NotificationSettingsEntity(
        globalChatsDndEnabled: false,
        globalChatsDndTimestamp: -1
    )

    @Published var isChatNotificationsEnabled: Bool = false
    @Published var muteNotificationsTimeString: String?
    @Published var isBottomSheetPresented = false
    
    var currentMuteNotificationPreset: TimeValuePreset?
    let muteNotificationsPresets: [TimeValuePreset] = TimeValuePreset.muteNotificationOptions()
    
    public init(
        notificationSettingsUseCase: some NotificationSettingsUseCaseProtocol
    ) {
        self.notificationSettingsUseCase = notificationSettingsUseCase
    }
    
    func fetchData() async {
        do {
            notificationSettings = try await notificationSettingsUseCase.getPushNotificationSettings()
            isChatNotificationsEnabled = !notificationSettings.globalChatsDndEnabled || notificationSettings.globalChatsDndTimestamp > 0
            mutedUntilString()
        } catch {
            MEGALogError("[Notification Settings] Error getting notification settings: \(error)")
        }
    }
    
    func toggleChatNotifications(isCurrentlyEnabled: Bool) async {
        do {
            notificationSettings.globalChatsDndEnabled = isCurrentlyEnabled
            if notificationSettings.globalChatsDndEnabled {
                notificationSettings.globalChatsDndTimestamp = 0
            }
            notificationSettings = try await notificationSettingsUseCase.setPushNotificationSettings(notificationSettings)
            isChatNotificationsEnabled = !isCurrentlyEnabled
        } catch {
            MEGALogError("[Notification Settings] Error setting notification settings: \(error)")
        }
    }
    
    func muteNotificationsTapped() {
        isBottomSheetPresented.toggle()
    }
    
    func muteNotificationsPresetTapped(_ preset: TimeValuePreset) async {
        do {
            if preset == .never {
                notificationSettings.globalChatsDndEnabled = false
                notificationSettings.globalChatsDndTimestamp =  Int64(preset.timeInterval)
            } else {
                notificationSettings.globalChatsDndEnabled = true
                notificationSettings.globalChatsDndTimestamp =  Int64(ceil(Date().timeIntervalSince1970 + preset.timeInterval))
            }
            notificationSettings = try await notificationSettingsUseCase.setPushNotificationSettings(notificationSettings)
            isBottomSheetPresented.toggle()
            mutedUntilString()
        } catch {
            MEGALogError("[Notification Settings] Error setting notification settings: \(error)")
        }
    }
    
    private func mutedUntilString() {
        if notificationSettings.globalChatsDndEnabled && notificationSettings.globalChatsDndTimestamp > 0 {
            let remainingTime = ceil(TimeInterval(notificationSettings.globalChatsDndTimestamp) - Date().timeIntervalSince1970)
            muteNotificationsTimeString = remainingTime.dndFormattedString
        } else {
            muteNotificationsTimeString = Strings.Localizable.never
        }
    }
}

extension TimeInterval {
    var dndFormattedString: String? {
        guard let date = Calendar.current.date(byAdding: .second, value: Int(ceil(self)), to: Date()) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: date)
                
        if Calendar.current.isDateInTomorrow(date) {
            return Strings.Localizable.notificationsWillBeSilencedUntilTomorrow(time)
        } else {
            let hour = Calendar.current.component(.hour, from: date)
            return Strings.Localizable.Chat.Info.Notifications.mutedUntilTime(hour)
                .replacingOccurrences(of: "[Time]", with: time)
        }
    }
}
