import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct NotificationSettingsView: View {
    @StateObject private var viewModel: NotificationSettingsViewModel
    
    public init(viewModel: @autoclosure @escaping () -> NotificationSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            chatNotificationsView
            muteNotificationsView
                .opacity(viewModel.isChatNotificationsEnabled ? 1 : 0)
        }
        .noInternetViewModifier()
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.Chat.Notifications.title)
        .task {
            await viewModel.fetchData()
        }
    }
    
    private var chatNotificationsView: some View {
        MEGAList(
            title: Strings.Localizable.Settings.Chat.Notifications.chatNotifications
        ).replaceTrailingView {
            MEGAToggle(state: .init(isOn: viewModel.isChatNotificationsEnabled)) { state in
                viewModel.toggleChatNotifications(isCurrentlyEnabled: state.isOn)
            }
        }
    }
    
    private var muteNotificationsView: some View {
        Button(action: viewModel.muteNotificationsTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Notifications.MuteNotifications.title,
                subtitle: viewModel.muteNotificationsTimeString
            )
            .trailingChevron()
        }
        .bottomSheet(
            isPresented: $viewModel.isBottomSheetPresented,
            detents: [.fixed(360)],
            showDragIndicator: true,
            cornerRadius: TokenRadius.large) {
                muteNotificationsPresetListView
            }
    }
    
    private var muteNotificationsPresetListView: some View {
        MEGAList(contentView: {
            ForEach(viewModel.muteNotificationsPresets) { preset in
                Button(action: { viewModel.muteNotificationsPresetTapped(preset)
                }, label: {
                    MEGAList(
                        title: preset.displayName
                    )
                    .trailingImage(icon: MEGAAssetsImageProvider.image(named: .check))
                    .trailingImageHidden(viewModel.currentMuteNotificationPreset != preset)
                })
            }
        }, headerView: {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Notifications.MuteNotifications.title
            )
            .titleFont(.headline)
            .padding([.top], TokenSpacing._6)
        })
        .pageBackground()
    }
}
