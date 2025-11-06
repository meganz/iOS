import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct SetStatusView: View {
    @StateObject private var viewModel: SetStatusViewModel
    
    public init(viewModel: @autoclosure @escaping () -> SetStatusViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            statusList
            statusSettings
        }
        .noInternetViewModifier()
        .pageBackground()
        .navigationTitle(Strings.Localizable.Settings.Chat.Status.SetStatus.title)
        .task {
            await viewModel.fetchData()
        }
    }
    
    private var statusList: some View {
        ForEach(viewModel.chatOnlineStatuses) { status in
            statusView(status)
        }
    }
    
    private func statusView(
        _ status: ChatStatusEntity
    ) -> some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 7.5, height: 7.5)
            Text(status.localizedIdentifier ?? "")
                .padding(.horizontal, TokenSpacing._5)
            Spacer()
            MEGARadioButton(isSelected: status == viewModel.currentStatus) {
                viewModel.onlineStatusTapped(status)
            }
        }
        .frame(height: 58)
        .padding(.horizontal, TokenSpacing._5)
    }
    
    private var statusSettings: some View {
        VStack(alignment: .leading) {
            Text(Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.title)
                .font(.subheadline)
                .padding(16)
            lastGreenView
            autoAwayView
                .opacity(viewModel.isAutoAwayVisible ? 1 : 0)
        }
    }
    
    private var lastGreenView: some View {
        MEGAList(
            title: Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.LastSeen.title,
            subtitle: Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.LastSeen.subtitle
        ).replaceTrailingView {
            MEGAToggle(state: .init(isOn: viewModel.isShowLastGreenEnabled)) { state in
                viewModel.toggleEnableShowLastGreen(isCurrentlyEnabled: state.isOn)
            }
        }
    }
    
    private var autoAwayView: some View {
        Button(action: viewModel.autoAwayTapped) {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.AutoAway.title,
                subtitle: viewModel.autoAwayTimeString
            )
            .trailingChevron()
        }
        .bottomSheet(
            isPresented: $viewModel.isBottomSheetPresented,
            showDragIndicator: true,
            cornerRadius: TokenRadius.large) {
                autoAwayPresetListView
            }
    }
    
    private var autoAwayPresetListView: some View {
        MEGAList(contentView: {
            ForEach(viewModel.autoAwayPresets) { preset in
                Button(action: { viewModel.autoAwayPresetTapped(preset)
                }, label: {
                    MEGAList(
                        title: preset.displayName
                    )
                    .trailingImage(icon: MEGAAssets.Image.check)
                    .trailingImageHidden(viewModel.currentAutoAwayPreset != preset)
                })
            }
        }, headerView: {
            MEGAList(
                title: Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.AutoAway.title
            )
            .titleFont(.headline)
            .padding([.top], TokenSpacing._6)
        })
        .pageBackground()
    }
}
