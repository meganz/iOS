import MEGAAssets
import MEGAConnectivity
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

public struct TransfersListView: View {
    private static let offlineSnackBarDisplayDuration: TimeInterval = Double(Int32.max)

    @StateObject private var viewModel: TransfersListViewModel

    init(viewModel: TransfersListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                    closeButtonAccessibilityLabel: Strings.Localizable.close,
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
        .task {
            await viewModel.observeNetworkConnection()
        }
        // Select mode is entered by tap-and-hold on a row, a gesture VoiceOver
        // takes for itself, and the bar it swaps in sits outside the focused
        // element — so without this the mode change happens silently.
        .onChange(of: viewModel.isSelectModeActive) { _, isActive in
            guard isActive else { return }
            AccessibilityNotification.Announcement(Strings.Localizable.selectTitle).post()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(Strings.Localizable.transfers)
        .navigationBarTitleDisplayMode(viewModel.isSelectModeActive ? .inline : .large)
        .navigationBarBackButtonHidden(viewModel.isSelectModeActive)
        .snackBar($viewModel.snackBar)
        .overlay(alignment: .bottom) {
            if viewModel.isOffline, viewModel.snackBar == nil {
                SnackBarView(
                    snackBar: .constant(viewModel.offlineSnackBar),
                    displayDuration: Self.offlineSnackBarDisplayDuration
                )
            }
        }
        .alert(
            viewModel.presentingCancelConfirmation?.title ?? "",
            isPresented: isPresentingCancelConfirmation,
            presenting: viewModel.presentingCancelConfirmation
        ) { confirmation in
            Button(confirmation.confirmTitle, role: confirmation.isConfirmDestructive ? .destructive : nil) {
                Task { await viewModel.confirmCancel(confirmation) }
            }
            Button(Strings.Localizable.dismiss, role: .cancel) {}
        } message: { confirmation in
            if let message = confirmation.message {
                Text(message)
            }
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
                    SelectModeTitle(selection: viewModel.selection)
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
                                    .foregroundStyle(topBarIconColor)
                            }
                            .disabled(viewModel.isOffline)
                            .accessibilityLabel(viewModel.isAllPaused
                                ? Strings.Localizable.resumeAll
                                : Strings.Localizable.pauseAll)
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
                                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                                    .foregroundStyle(topBarIconColor)
                            }
                            .disabled(viewModel.isOffline)
                            .accessibilityLabel(Strings.Localizable.more)
                        }
                    }
                }
            }
        }
    }

    /// The alert's presentation binding, derived from the scope the view model holds:
    /// one dialog serves both cancel entry points, and dismissing it clears the pending scope.
    private var isPresentingCancelConfirmation: Binding<Bool> {
        Binding(
            get: { viewModel.presentingCancelConfirmation != nil },
            set: { isPresented in
                guard !isPresented else { return }
                // Deferred out of the current update pass. The alert writes
                // `false` back while SwiftUI is still updating the view tree, so
                // clearing the scope synchronously publishes into that same pass
                // — which SwiftUI reports as undefined behaviour.
                Task { @MainActor in
                    viewModel.presentingCancelConfirmation = nil
                }
            }
        )
    }

    // MARK: - Select mode
    //
    // The pieces that read the selection observe it from their own small views,
    // built here in `body` from `viewModel.selection`. Holding an
    // `@ObservedObject` on this view instead would capture it at init time,
    // while `@StateObject` keeps whichever view model it was first given — so a
    // re-created view with a different view model would render one generation's
    // selection while the tab list mutated another's.

    private var selectAllButton: some View {
        Button {
            viewModel.selection.toggleSelectAll()
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
    /// reachable. Each button acts on the selected subset and leaves select mode;
    /// only cancel goes through the confirmation dialog first. Retry carries one
    /// extra enablement condition: it needs a selection with something retryable in
    /// it, or the tap would skip every row (see `canRetrySelectedTransfers`).
    private var selectModeActionButtons: some View {
        HStack(spacing: 0) {
            if viewModel.selectedTab == .failed {
                SelectModeActionButton(
                    selection: viewModel.selection,
                    icon: MEGAAssets.Image.rotateCcw,
                    label: Strings.Localizable.retry,
                    isOfflineBlocked: viewModel.isOffline,
                    isActionable: { viewModel.canRetrySelectedTransfers },
                    action: viewModel.retrySelectedTransfers
                )
            }
            Spacer()
            switch viewModel.selectedTab {
            case .active:
                SelectModeActionButton(
                    selection: viewModel.selection,
                    icon: MEGAAssets.Image.rubbishBinInMenu,
                    label: Strings.Localizable.cancel,
                    isOfflineBlocked: viewModel.isOffline,
                    action: viewModel.confirmCancelSelectedTransfers
                )
            case .completed, .failed:
                SelectModeActionButton(
                    selection: viewModel.selection,
                    icon: MEGAAssets.Image.monoEraserMediumThinOutline,
                    label: Strings.Localizable.clear,
                    isOfflineBlocked: viewModel.isOffline,
                    action: viewModel.clearSelectedTransfers
                )
            }
        }
        .padding(TokenSpacing._5)
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
        case .cancelAll: viewModel.confirmCancelAllTransfers()
        case .clearAll: viewModel.clearAllTransfers()
        case .retryAll: Task { await viewModel.retryAllTransfers() }
        }
    }

    private var topBarIconColor: Color {
        viewModel.isOffline
            ? TokenColors.Icon.disabled.swiftUI
            : TokenColors.Icon.primary.swiftUI
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
            onTransferRetried: { viewModel.didRetryTransfers() },
            onRowSelectRequested: { viewModel.enterSelectMode(preselecting: $0) }
        )
            .id(viewModel.selectedTab)
            .environment(\.editMode, $viewModel.editMode)
            .environment(\.isAllTransfersPaused, viewModel.isAllPaused)
            .environment(\.isTransferOverquota, viewModel.isTransferOverquota)
            .environment(\.isTransfersOffline, viewModel.isOffline)
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
        // The selected tab is marked by weight and an underline, neither of which
        // VoiceOver can see; the trait is what makes it say "selected".
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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

/// "Select items" until the first row is ticked, then the plural-aware
/// "N item(s) selected", as the design frames show.
private struct SelectModeTitle: View {
    @ObservedObject var selection: TransferSelection

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .lineLimit(1)
    }

    private var title: String {
        let count = selection.count
        return count == 0
            ? Strings.Localizable.selectTitle
            : Strings.Localizable.General.Format.itemsSelected(count)
    }
}

/// One floating glass circle from the design's bottom toolbar, enabled only
/// while something is selected. Observes the selection itself so enablement
/// lands in the same frame as the tap that changed it.
private struct SelectModeActionButton: View {
    @ObservedObject var selection: TransferSelection
    let icon: Image
    let label: String
    let isOfflineBlocked: Bool
    /// Whether the selected rows have anything for this action to do — the gate on
    /// top of "something is selected, and we are online". Evaluated inside `body`,
    /// so it is re-read whenever the observed selection changes; a value computed
    /// by the parent would go stale, since the screen's own view model publishes
    /// nothing on a row tap. Defaults to no extra condition: every action but Retry
    /// can act on any row the tab lists.
    var isActionable: @MainActor () -> Bool = { true }
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
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

    private var isEnabled: Bool {
        !selection.isEmpty && !isOfflineBlocked && isActionable()
    }
}
