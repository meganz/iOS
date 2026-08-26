import Foundation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Row layout for the new Transfers screen, with two variants driven by status:
///
/// - Active (and other in-flight states): file-type icon, file name, "↑ 48% · 30 MB
///   of 100 MB · 4.2 MB/s" subtitle, trailing pause/play icon, and a state-tinted
///   linear progress bar at the bottom.
/// - Read-only terminal states (Completed / Failed / Cancelled): file-type icon, file
///   name, an inert more button, and no progress bar. Completed additionally shows the file
///   system path on a second line and "↑ 7 MB · 10 Aug 2024 19:09" on a third line;
///   Failed and Cancelled show a "↑ Failed" / "↑ Cancelled" state label instead.
///
/// Observes one `TransferRowViewModel` so 1 Hz progress updates re-render only this
/// row.
struct TransferResultRowView: View {
    @ObservedObject var viewModel: TransferRowViewModel
    /// Invoked after a swipe-cancel lands in the engine, with the cancelled entity;
    /// the screen shows the undo snackbar.
    let onCancelled: (TransferEntity) -> Void
    /// Invoked after a retry (leading swipe or sheet action) lands in the engine;
    /// the screen shows the retry snackbar.
    let onRetried: @MainActor () -> Void
    /// Invoked when Select is chosen from the tap-and-hold menu; the screen enters
    /// select mode with this row pre-selected.
    let onSelectRequested: @MainActor () -> Void
    @Environment(\.isAllTransfersPaused) private var isAllTransfersPaused
    @Environment(\.isTransferOverquota) private var isTransferOverquota
    @Environment(\.isTransfersOffline) private var isOffline
    @Environment(\.editMode) private var editMode

    /// In select mode the row shows the native leading checkbox and nothing may
    /// compete with the tap that toggles it, so the trailing control is dropped
    /// and the row's own gestures are masked off.
    private var isSelecting: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    /// Pause/resume is disabled while all transfers are paused or transfer quota is
    /// exhausted (nothing can progress until the user upgrades).
    private var isPauseResumeDisabled: Bool {
        isAllTransfersPaused || isTransferOverquota
    }

    /// Pause/resume cannot start anything while offline either, and the persistent
    /// offline snackbar already says why, so the control is simply inert there.
    private var isPauseResumeInert: Bool {
        isPauseResumeDisabled || isOffline
    }

    private var isMoreInert: Bool {
        isOffline && !isCompleted
    }

    /// What the row renders, which is the engine's state except while offline: nothing
    /// can transfer without a connection, so in-flight rows all read as Paused
    private var displayState: TransferRowState {
        guard isOffline, !isReadOnly else { return viewModel.state }
        var state = viewModel.state
        state.status = .paused
        return state
    }

    private var isCompleted: Bool {
        viewModel.state.status == .completed
    }

    /// The lifted card's corner radius. UIKit masks the preview to this path, so
    /// the card needs no clip of its own; left to itself it rounds a preview more
    /// heavily than the design does.
    private let previewCornerRadius: CGFloat = 10

    /// Terminal states render a static, row with no progress bar.
    private var isReadOnly: Bool {
        switch viewModel.state.status {
        case .completed, .failed, .cancelled: true
        case .queued, .active, .paused: false
        }
    }

    var body: some View {
        rowContent
        .contentShape(Rectangle())
        // Shapes the lifted card. Left to itself SwiftUI rounds it more heavily than the design does.
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: previewCornerRadius))
        // Masked rather than removed while selecting: an `if` around the gesture
        // and swipe modifiers would be a structural change, so entering select
        // mode would tear down and rebuild every visible row. A masked-off
        // gesture stops consuming the tap, leaving it to the list's selection.
        .gesture(
            TapGesture().onEnded {
                if isCompleted { viewModel.openFile() }
            },
            including: isSelecting ? .none : .all
        )
        .contextMenu {
            if !isSelecting {
                selectMenuItem
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting, !isOffline {
                swipeAction
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSelecting, !isOffline, viewModel.state.isRetryable {
                retrySwipeAction
            }
        }
        .task(id: viewModel.thumbnailRetryTrigger) {
            await viewModel.loadThumbnail()
        }
    }

    /// The row's visuals, with no gestures or list wiring attached. Shared with the
    /// tap-and-hold preview so the lifted platter can't drift from the real row.
    private var rowContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: TokenSpacing._4) {
                summary

                if !isSelecting {
                    trailingAction
                }
            }
            .padding(TokenSpacing._4)

            if !isReadOnly {
                ProgressView(value: viewModel.state.progress)
                    .progressViewStyle(CapsuleProgressViewStyle(tint: progressTint, height: 2))
                    // Hidden from VoiceOver only — the bar still renders. A
                    // ProgressView is an element in its own right and announces
                    // its own "48%", which the row's label already says as its
                    // middle component, so the row would read the figure twice.
                    .accessibilityHidden(true)
            }
        }
    }

    /// Thumbnail and text as one VoiceOver element reading
    /// `<file name>, <state>, <progress>`, rather than four in a row
    ///
    /// Grouped in its own stack rather than at the row level on purpose: the row
    /// also holds the pause / more button, which has to stay separately reachable.
    private var summary: some View {
        HStack(spacing: TokenSpacing._4) {
            leadingThumbnail

            VStack(alignment: .leading, spacing: TokenSpacing._2) {
                Text(viewModel.state.fileName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .lineLimit(1)

                if isCompleted, let location = viewModel.state.location {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(displayState.subtitle)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(displayState.accessibilityLabel)
        .accessibilityValue(displayState.accessibilityValue)
        .accessibilityAddTraits(summaryTraits)
        // Select mode is only reachable by tap-and-hold, and VoiceOver keeps that
        // gesture for itself — an affordance behind a gesture needs a spoken
        // equivalent
        .accessibilityActions {
            if !isSelecting {
                Button(Strings.Localizable.select) {
                    onSelectRequested()
                }
            }
        }
    }

    /// Whether activating the row opens the file: the completed-row tap gesture,
    /// which is masked off while selecting.
    private var isOpenable: Bool {
        isCompleted && !isSelecting
    }

    private var summaryTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        // Completed rows open the file when tapped, so they read as a button and
        // answer VoiceOver's activate
        if isOpenable {
            traits.formUnion(.isButton)
        }
        // An in-flight row republishes its percentage on every SDK transfer
        // callback, unthrottled — only row membership goes through the list's
        // one-second throttle, progress does not. The trait turns that from push
        // into pull: VoiceOver stops treating each change as an event to relay
        // and instead polls the value while the row holds focus.
        if !isReadOnly {
            traits.formUnion(.updatesFrequently)
        }
        return traits
    }

    /// The single entry in the tap-and-hold menu.
    ///
    /// Title and icon are all we get to choose: the cell is a native `UIAction`, so
    /// the system owns its layout, shape and material. The design's cell (title
    /// leading, icon trailing, 12pt corners) is how iOS 18 draws this; iOS 26 draws
    /// the same menu as a glass capsule with the icon leading instead.
    private var selectMenuItem: some View {
        Button {
            onSelectRequested()
        } label: {
            Label {
                Text(Strings.Localizable.select)
            } icon: {
                MEGAAssets.Image.monoCheckSquareMediumThinOutline
            }
        }
    }

    /// Right-to-left swipe: cancel on in-flight rows (trash), clear on terminal rows
    /// (eraser). `.destructive` renders the design's pinned red button; row removal
    /// is driven by the resulting membership event, and cancels bubble up through
    /// `onCancelled` for the undo snackbar.
    private var swipeAction: some View {
        Button(role: .destructive) {
            if isReadOnly {
                viewModel.clear()
            } else {
                Task {
                    if let cancelled = await viewModel.cancel() {
                        onCancelled(cancelled)
                    }
                }
            }
        } label: {
            // Named on the image, not on the button. A swipe action reaches
            // VoiceOver as a custom action whose name is taken from the label's
            // *content*; with a bare image that name is the asset's own — the
            // rotor read this one out as "rubbishBinInMenu" for example.
            swipeIcon
                .accessibilityLabel(isReadOnly
                    ? Strings.Localizable.clear
                    : Strings.Localizable.Transfers.Cancellable.cancel)
        }
    }

    @ViewBuilder
    private var swipeIcon: some View {
        if isReadOnly {
            MEGAAssets.Image.monoEraserMediumThinOutline
        } else {
            MEGAAssets.Image.rubbishBinInMenu
        }
    }

    /// Real thumbnail when the loader produced one (cached SDK thumbnail for
    /// downloads, QuickLook-generated for uploads); file-type icon otherwise.
    @ViewBuilder
    private var leadingThumbnail: some View {
        if let thumbnail = viewModel.thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        } else {
            MEGAAssets.Image.image(forFileName: viewModel.state.fileName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
    }
        
    /// Left-to-right swipe on Failed-tab rows: the design's blue retry affordance.
    /// Re-queues the transfer (row removal is driven by the cleared signal) and
    /// bubbles up through `onRetried` for the retry snackbar.
    private var retrySwipeAction: some View {
        Button {
            Task {
                if await viewModel.retry() {
                    onRetried()
                }
            }
        } label: {
            MEGAAssets.Image.rotateCcw
                .accessibilityLabel(Strings.Localizable.retry)
        }
        .tint(TokenColors.Support.info.swiftUI)
    }

    /// In-flight rows show a pause/play toggle; terminal rows show the `…` button that
    /// presents the per-row action sheet.
    @ViewBuilder
    private var trailingAction: some View {
        if isReadOnly {
            Button {
                viewModel.presentActions(isOffline: isOffline, onRetried: onRetried)
            } label: {
                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                    .foregroundStyle(isMoreInert
                        ? TokenColors.Icon.disabled.swiftUI
                        : TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 24, height: 24)
                    .expandedHitTarget()
            }
            .buttonStyle(.plain)
            .disabled(isMoreInert)
            .accessibilityLabel(Strings.Localizable.more)
        } else {
            pauseResumeButton
        }
    }

    private var pauseResumeButton: some View {
        Button {
            Task { await viewModel.togglePauseResume() }
        } label: {
            trailingImage
                .foregroundStyle(isPauseResumeInert
                    ? TokenColors.Icon.disabled.swiftUI
                    : TokenColors.Icon.secondary.swiftUI)
                .frame(width: TokenSpacing._7, height: TokenSpacing._7)
                .expandedHitTarget()
        }
        .buttonStyle(.plain)
        .disabled(isPauseResumeInert)
        // Named for what pressing it does, not for the state the row is in. The
        // button is icon-only, so without a label VoiceOver falls back to the
        // asset's own name and reads out "pause-medium-thin-outline".
        .accessibilityLabel(displayState.status == .paused
            ? Strings.Localizable.resume
            : Strings.Localizable.pause)
    }

    /// Failed rows show their state label in red; every other status (including
    /// the user-cancelled grey label) uses the standard secondary tint.
    private var subtitleColor: Color {
        switch displayState.status {
        case .failed: TokenColors.Support.error.swiftUI
        case .queued, .active, .paused, .completed, .cancelled: TokenColors.Text.secondary.swiftUI
        }
    }

    private var progressTint: Color {
        switch displayState.status {
        case .failed, .cancelled: TokenColors.Support.error.swiftUI
        case .paused, .queued: TokenColors.Text.secondary.swiftUI
        case .active, .completed: TokenColors.Support.success.swiftUI
        }
    }

    private var trailingImage: Image {
        switch displayState.status {
        case .active, .queued: MEGAAssets.Image.pauseMediumThinOutline
        case .paused: MEGAAssets.Image.monoPlayMediumThinOutline
        case .completed, .failed, .cancelled: MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
        }
    }
}

private extension View {
    /// Grows a control's touch target by (2 x `TokenSpacing._4`)pt — past the 44pt floor the HIG sets —
    /// without moving a pixel: the hit region is inset by `_4` on every side and
    /// the matching negative padding takes that inset back out of the layout.
    ///
    /// The row's trailing icons are 24pt and sit in the 16pt gutter, directly
    /// under the list's scroll indicator, so a tap that lands a few points wide
    /// of a bare icon is read as the start of a scroll instead of a press.
    func expandedHitTarget() -> some View {
        padding(TokenSpacing._4)
            .contentShape(Rectangle())
            .padding(-TokenSpacing._4)
    }
}

private struct IsAllTransfersPausedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct IsTransferOverquotaKey: EnvironmentKey {
    static let defaultValue = false
}

private struct IsTransfersOfflineKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isAllTransfersPaused: Bool {
        get { self[IsAllTransfersPausedKey.self] }
        set { self[IsAllTransfersPausedKey.self] = newValue }
    }

    var isTransferOverquota: Bool {
        get { self[IsTransferOverquotaKey.self] }
        set { self[IsTransferOverquotaKey.self] = newValue }
    }

    var isTransfersOffline: Bool {
        get { self[IsTransfersOfflineKey.self] }
        set { self[IsTransfersOfflineKey.self] = newValue }
    }
}
