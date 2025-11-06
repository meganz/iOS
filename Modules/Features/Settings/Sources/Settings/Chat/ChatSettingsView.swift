import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct ChatSettingsView: View {
    @StateObject private var viewModel: ChatSettingsViewModel
    
    public init(viewModel: @autoclosure @escaping () -> ChatSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                onlineStatusView
                notificationSettingsView
                mediaQualityView
                richUrlPreviewView
            }
        }
        .noInternetViewModifier()
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.Chat.title)
        .task {
            await viewModel.fetchData()
        }
    }
    
    private var onlineStatusView: some View {
        Button(action: viewModel.statusViewTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Status.title,
                subtitle: viewModel.onlineStatusString
            )
            .trailingChevron()
        }
    }
    
    private var notificationSettingsView: some View {
        Button(action: viewModel.notificationsViewTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Notifications.title
            )
            .trailingChevron()
        }
    }
    
    private var mediaQualityView: some View {
        Button(action: viewModel.mediaQualityViewTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.MediaQuality.title
            )
            .trailingChevron()
        }
    }
    
    private var richUrlPreviewView: some View {
        MEGAList(
            title: Strings.Localizable.Settings.Chat.RichUrlPreview.title,
            subtitle: Strings.Localizable.Settings.Chat.RichUrlPreview.subtitle
        ).replaceTrailingView {
            MEGAToggle(state: .init(isOn: viewModel.isRichLinkPreviewEnabled)) { state in
                viewModel.toggleEnableRichLinkPreview(isCurrentlyEnabled: state.isOn)
            }
        }
    }
}
