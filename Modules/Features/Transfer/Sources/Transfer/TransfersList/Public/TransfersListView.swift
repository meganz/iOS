import MEGAAssets
import MEGAConnectivity
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct TransfersListView: View {
    @StateObject private var viewModel: TransfersListViewModel
    /// Observed directly rather than republished through the screen view model, so
    /// the select-mode count and action enablement update in the same frame as the
    /// tap that changed the selection.
    @ObservedObject private var selection: TransferSelection

    init(viewModel: TransfersListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selection = ObservedObject(wrappedValue: viewModel.selection)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // The tab switcher hides while selecting: the selection is per-tab.
            if viewModel.hasAnyTransfers, !viewModel.isSelectModeActive {
                tabBar
                Divider()
            }
            if let banner = viewModel.overQuotaBanner {
                MEGABanner(
                    title: banner.title,
                    subtitle: String?.none,
                    buttonText: banner.actionTitle,
                    state: banner.bannerState,
                    buttonAction: { viewModel.showUpgrade() },
                    closeButtonAction: banner.showsDismiss ? { viewModel.dismissOverQuotaBanner() } : nil
                )
            }
            tabContent
                .noInternetViewModifier(viewModel: MEGAConnectivity.DependencyInjection.networkPathNoInternetViewModel)
        }
        .task {
            await viewModel.observeTabPresence()
        }
        .task {
            await viewModel.observeStorageQuota()
        }
        .task {
            await viewModel.observeTransferQuota()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(Strings.Localizable.transfers)
        .navigationBarTitleDisplayMode(viewModel.isSelectModeActive ? .inline : .large)
        .navigationBarBackButtonHidden(viewModel.isSelectModeActive)
        .snackBar($viewModel.snackBar)
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
            // Both leading buttons are SwiftUI-owned so select mode can swap one
            // for the other atomically. A presenter-attached UIKit item can't take
            // part in that swap — it would render beside the SwiftUI one — which
            // is why modal presenters inject `onClose` instead of adding their own.
            if viewModel.isSelectModeActive {
                ToolbarItem(placement: .topBarLeading) {
                    selectAllButton
                }
                ToolbarItem(placement: .principal) {
                    Text(selectModeTitle)
                        .font(.headline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton
                }
            } else {
                if let onClose = viewModel.onClose {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton(onClose)
                    }
                }
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
    }

    // MARK: - Select mode

    /// "Select items" until the first row is ticked, then the plural-aware
    /// "N item(s) selected", as the design frames show.
    private var selectModeTitle: String {
        let count = selection.count
        return count == 0
            ? Strings.Localizable.selectTitle
            : Strings.Localizable.General.Format.itemsSelected(count)
    }

    private var selectAllButton: some View {
        Button {
            selection.toggleSelectAll()
        } label: {
            MEGAAssets.Image.checkCircle
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        }
        .accessibilityLabel(Strings.Localizable.selectAll)
    }

    private var doneButton: some View {
        Button {
            viewModel.exitSelectMode()
        } label: {
            Text(Strings.Localizable.done)
                .font(.body.weight(.medium))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }

    private func closeButton(_ onClose: @escaping @MainActor () -> Void) -> some View {
        Button(action: onClose) {
            Text(Strings.Localizable.close)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }

    /// The tab's select-mode actions as floating glass circles, placed as the
    /// design frames show (Figma Transfer-Manager 1221-12497 / 1250-44286 /
    /// 1250-44043): the destructive action bottom-trailing, and on Failed a retry
    /// button bottom-leading. Rendered as a safe-area inset rather than an
    /// overlay so the list can scroll clear of them and the last row stays
    /// reachable. Running the actions on the selection lands with IOS-12220.
    private var selectModeActionButtons: some View {
        HStack(spacing: 0) {
            if viewModel.selectedTab == .failed {
                selectModeActionButton(
                    icon: MEGAAssets.Image.rotateCcw,
                    label: Strings.Localizable.retry,
                    action: viewModel.retrySelectedTransfers
                )
            }
            Spacer()
            switch viewModel.selectedTab {
            case .active:
                selectModeActionButton(
                    icon: MEGAAssets.Image.rubbishBinInMenu,
                    label: Strings.Localizable.cancel,
                    action: viewModel.cancelSelectedTransfers
                )
            case .completed, .failed:
                selectModeActionButton(
                    icon: MEGAAssets.Image.monoEraserMediumThinOutline,
                    label: Strings.Localizable.clear,
                    action: viewModel.clearSelectedTransfers
                )
            }
        }
        .padding(TokenSpacing._5)
    }

    private func selectModeActionButton(
        icon: Image,
        label: String,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        let isEnabled = !selection.isEmpty
        return Button(action: action) {
            icon
                .foregroundStyle(isEnabled
                    ? TokenColors.Icon.primary.swiftUI
                    : TokenColors.Icon.disabled.swiftUI)
                // The design builds this button as its 24pt icon inset by
                // spacing/4 on every side, which lands the circle at 48pt.
                .padding(TokenSpacing._4)
        }
        .glassCircleBackground()
        .disabled(!isEnabled)
        .accessibilityLabel(label)
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
        case .retryAll: Task { await viewModel.retryAllTransfers() }
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if viewModel.isSelectModeActive {
                    selectModeActionButtons
                }
            }
    }

    // Re-keyed by tab via `.id`, so switching tabs tears down the previous tab's
    // list view model and its event-stream task: only the selected tab observes
    // the SDK delegate streams. The environment values only affect Active rows;
    // read-only Completed/Failed rows ignore them.
    private var tabContainer: some View {
        TransferTabListView(
            tab: viewModel.selectedTab,
            dependency: viewModel.dependency,
            selection: viewModel.selection,
            onTransferCancelled: { viewModel.didCancelTransfer($0) },
            onTransferRetried: { viewModel.didRetryTransfers() }
        )
            .id(viewModel.selectedTab)
            .environment(\.editMode, $viewModel.editMode)
            .environment(\.isAllTransfersPaused, viewModel.isAllPaused)
            .environment(\.isTransferOverquota, viewModel.isTransferOverquota)
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

private extension View {
    /// The floating action circle from the design frames: liquid glass on iOS 26,
    /// a flat surface-1 circle before that — the same shape and fallback the mini
    /// player and Accounts ship for their glass affordances.
    @ViewBuilder
    func glassCircleBackground() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background(TokenColors.Background.surface1.swiftUI, in: Circle())
        }
    }
}
