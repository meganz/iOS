import Foundation
import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import Search
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
    @Environment(\.isAllTransfersPaused) private var isAllTransfersPaused

    private var isCompleted: Bool {
        viewModel.state.status == .completed
    }

    /// Terminal states render a static, row with no progress bar.
    private var isReadOnly: Bool {
        switch viewModel.state.status {
        case .completed, .failed, .cancelled: true
        case .queued, .active, .paused: false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: TokenSpacing._4) {
                MEGAAssets.Image.image(forFileName: viewModel.state.fileName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

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
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingAction
            }
            .padding(TokenSpacing._4)

            if !isReadOnly {
                ProgressView(value: viewModel.state.progress)
                    .progressViewStyle(CapsuleProgressViewStyle(tint: progressTint, height: 2))
            }
        }
    }

    private var trailingAction: some View {
        Button {
            // Wired later
        } label: {
            trailingImage
                .foregroundStyle(isAllTransfersPaused
                    ? TokenColors.Icon.disabled.swiftUI
                    : TokenColors.Icon.secondary.swiftUI)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(isAllTransfersPaused)
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
        case .completed, .failed, .cancelled: MEGAAssets.Image.moreVerticalMediumThinOutline
        }
    }
}

private struct IsAllTransfersPausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isAllTransfersPaused: Bool {
        get { self[IsAllTransfersPausedKey.self] }
        set { self[IsAllTransfersPausedKey.self] = newValue }
    }
}
