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
    @Environment(\.editMode) private var editMode
    /// The row's width as laid out in the list, measured for the tap-and-hold preview.
    @State private var rowWidth: CGFloat = 0

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

    private var isCompleted: Bool {
        viewModel.state.status == .completed
    }

    /// Width of the lifted card in the tap-and-hold preview: the row inset by the
    /// design's 16pt gutter on both sides. `nil` until the row has been laid out once, which leaves
    /// the frame unconstrained rather than collapsing it to zero.
    private var previewWidth: CGFloat? {
        rowWidth > 0 ? rowWidth - TokenSpacing._5 * 2 : nil
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
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) { _, width in
                        rowWidth = width
                    }
            }
        }
        .contentShape(Rectangle())
        // Read off the row, not off the preview content: this is where SwiftUI
        // takes the path from when it hands UIKit the lifted preview's parameters.
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
        } preview: {
            rowContent
                .frame(width: previewWidth)
                .background(TokenColors.Background.page.swiftUI)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting {
                swipeAction
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSelecting, viewModel.state.isRetryable {
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

                    Text(viewModel.state.subtitle)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isSelecting {
                    trailingAction
                }
            }
            .padding(TokenSpacing._4)

            if !isReadOnly {
                ProgressView(value: viewModel.state.progress)
                    .progressViewStyle(CapsuleProgressViewStyle(tint: progressTint, height: 2))
            }
        }
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
            if isReadOnly {
                MEGAAssets.Image.monoEraserMediumThinOutline
            } else {
                MEGAAssets.Image.rubbishBinInMenu
            }
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
        }
        .tint(TokenColors.Support.info.swiftUI)
    }

    /// In-flight rows show a pause/play toggle; terminal rows show the `…` button that
    /// presents the per-row action sheet.
    @ViewBuilder
    private var trailingAction: some View {
        if isReadOnly {
            Button {
                viewModel.presentActions(onRetried: onRetried)
            } label: {
                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                Task { await viewModel.togglePauseResume() }
            } label: {
                trailingImage
                    .foregroundStyle(isPauseResumeDisabled
                        ? TokenColors.Icon.disabled.swiftUI
                        : TokenColors.Icon.secondary.swiftUI)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(isPauseResumeDisabled)
        }
    }

    /// Failed rows show their state label in red; every other status (including
    /// the user-cancelled grey label) uses the standard secondary tint.
    private var subtitleColor: Color {
        switch viewModel.state.status {
        case .failed: TokenColors.Support.error.swiftUI
        case .queued, .active, .paused, .completed, .cancelled: TokenColors.Text.secondary.swiftUI
        }
    }

    private var progressTint: Color {
        switch viewModel.state.status {
        case .failed, .cancelled: TokenColors.Support.error.swiftUI
        case .paused, .queued: TokenColors.Text.secondary.swiftUI
        case .active, .completed: TokenColors.Support.success.swiftUI
        }
    }

    private var trailingImage: Image {
        switch viewModel.state.status {
        case .active, .queued: MEGAAssets.Image.pauseMediumThinOutline
        case .paused: MEGAAssets.Image.monoPlayMediumThinOutline
        case .completed, .failed, .cancelled: MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
        }
    }
}

private struct IsAllTransfersPausedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct IsTransferOverquotaKey: EnvironmentKey {
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
}
