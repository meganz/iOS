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
        VStack(spacing: TokenSpacing._2) {
            // Title View
            Text(Strings.Localizable.Settings.Chat.Status.SetStatus.StatusSettings.AutoAway.title)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.top, TokenSpacing._12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TokenSpacing._4)
            
            // List View
            VStack(spacing: .zero) {
                ForEach(viewModel.autoAwayPresets) { preset in
                    Button(action: {
                        viewModel.autoAwayPresetTapped(preset)
                    }, label: {
                        autoAwayPresetRowView(preset)
                    })
                }
            }
            .padding(.top, TokenSpacing._3)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .background(
            TokenColors.Background.surface1.swiftUI,
            ignoresSafeAreaEdges: .all
        )
    }
    
    private func autoAwayPresetRowView(
        _ preset: AutoAwayPreset
    ) -> some View {
        HStack(spacing: .zero) {
            Text(preset.displayName)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            
            Spacer()
            
            if preset == viewModel.currentAutoAwayPreset {
                Image(uiImage: MEGAAssetsImageProvider.image(named: "check"))
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 32, height: 32, alignment: .center)
            }
        }
        .frame(height: 58)
        .padding(.horizontal, TokenSpacing._5)
    }
}
