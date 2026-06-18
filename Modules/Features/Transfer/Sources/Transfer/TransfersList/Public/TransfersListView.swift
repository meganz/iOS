import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct TransfersListView: View {
    @StateObject private var viewModel: TransfersListViewModel

    init(viewModel: TransfersListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasAnyTransfers {
                tabBar
                Divider()
            }
            tabContent
        }
        .task {
            await viewModel.observeTabPresence()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(Strings.Localizable.transfers)
        .navigationBarTitleDisplayMode(.large)
        .alert(
            Strings.Localizable.Transfers.Confirmation.CancelAll.title,
            isPresented: $viewModel.isPresentingCancelAllConfirmation
        ) {
            Button(Strings.Localizable.Transfers.Confirmation.CancelAll.confirm, role: .destructive) {
                viewModel.confirmCancelAll()
            }
            Button(Strings.Localizable.dismiss, role: .cancel) {}
        }
        .toolbar {
            if viewModel.hasAnyTransfers {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.selectedTab == .active {
                        Button {
                            viewModel.togglePauseAll()
                        } label: {
                            pauseAllIcon
                                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        }
                    }
                    if viewModel.showsMoreMenu {
                        Menu {
                            ForEach(viewModel.menuActions) { action in
                                Button {
                                    handle(action)
                                } label: {
                                    Label {
                                        Text(action.title)
                                    } icon: {
                                        icon(for: action)
                                    }
                                }
                            }
                        } label: {
                            MEGAAssets.Image.moreVerticalMediumThinOutline
                                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        }
                    }
                }
            }
        }
    }

    private func icon(for action: TransferMoreMenuAction) -> Image {
        switch action {
        case .select: MEGAAssets.Image.selectAllItems
        case .cancelAll: MEGAAssets.Image.rubbishBinInMenu
        case .clearAll: MEGAAssets.Image.monoEraserMediumThinOutline
        case .retryAll: MEGAAssets.Image.rotateCcw
        }
    }

    private func handle(_ action: TransferMoreMenuAction) {
        switch action {
        case .select: viewModel.enterSelectMode()
        case .cancelAll: viewModel.requestCancelAllConfirmation()
        case .clearAll: viewModel.clearAllTransfers()
        case .retryAll: viewModel.retryAllTransfers()
        }
    }

    private var pauseAllIcon: Image {
        viewModel.isAllPaused
            ? MEGAAssets.Image.monoPlayMediumThinOutline
            : MEGAAssets.Image.pauseMediumThinOutline
    }

    // When the current tab is empty its container renders a tab-specific empty state
    // (e.g. "No active transfers"). While there are no transfers on any tab, cover that
    // with the generic "No transfers" instead. Driven by `hasAnyTransfers` from the
    // count observer, the overlay clears reactively the moment any transfer appears.
    private var tabContent: some View {
        tabContainer
            .overlay {
                if !viewModel.hasAnyTransfers {
                    RevampedContentUnavailableView(
                        viewModel: .transfersEmptyState(title: Strings.Localizable.Transfers.EmptyState.noTransfers)
                    )
                    .pageBackground()
                }
            }
    }

    // Each tab is its own view type, so switching tabs tears down the previous tab and
    // builds the next: the dismissed tab's Search container is released and only the
    // selected tab observes the SDK delegate streams.
    @ViewBuilder
    private var tabContainer: some View {
        switch viewModel.selectedTab {
        case .active:
            ActiveTransfersTab(dependency: viewModel.dependency, isAllPaused: viewModel.isAllPaused)
        case .completed:
            CompletedTransfersTab(dependency: viewModel.dependency)
        case .failed:
            FailedTransfersTab(dependency: viewModel.dependency)
        }
    }

    private var tabBar: some View {
        HStack(spacing: TokenSpacing._7) {
            ForEach(TransfersTab.allCases) { tab in
                tabButton(tab)
            }
            Spacer()
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.top, TokenSpacing._3)
    }

    private func tabButton(_ tab: TransfersTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Text(tab.title)
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected
                        ? TokenColors.Button.brand.swiftUI
                        : TokenColors.Text.secondary.swiftUI)
                Rectangle()
                    .fill(isSelected ? TokenColors.Button.brand.swiftUI : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
