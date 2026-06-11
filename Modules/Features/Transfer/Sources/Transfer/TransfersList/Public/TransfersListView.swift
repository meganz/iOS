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
        .onAppear {
            viewModel.seedCompletedPresence()
            viewModel.seedFailedPresence()
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

    // The Active container stays mounted even with no transfers, so its result-
    // monitoring task keeps running and a transfer that starts here is still detected.
    // It would render "No active transfers" while empty, so cover it with the generic
    // "No transfers" instead. Driven by `hasAnyTransfers`, this clears reactively the
    // moment any transfer appears — something the container's own empty view can't do,
    // since it only recomputes on a results refresh.
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

    @ViewBuilder
    private var tabContainer: some View {
        switch viewModel.selectedTab {
        case .active:
            ActiveTransfersTab(
                dependency: viewModel.dependency,
                isAllPaused: viewModel.isAllPaused,
                presence: $viewModel.activePresence
            )
        case .completed:
            CompletedTransfersTab(
                dependency: viewModel.dependency,
                presence: $viewModel.completedPresence
            )
        case .failed:
            FailedTransfersTab(
                dependency: viewModel.dependency,
                presence: $viewModel.failedPresence
            )
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
