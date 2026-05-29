import Foundation
import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import Search
import SwiftUI

/// Active-tab row layout matching the design: file-type icon, file name, "↑ 48% ·
/// 30 MB of 100 MB · 4.2 MB/s" subtitle, trailing pause/play (or kebab) icon, and
/// a linear progress bar at the bottom tinted by state. Observes one
/// `TransferRowViewModel` so 1 Hz progress updates re-render only this row.
struct TransferResultRowView: View {
    @ObservedObject var viewModel: TransferRowViewModel

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

                    Text(viewModel.state.subtitle)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingAction
            }
            .padding(TokenSpacing._4)

            ProgressView(value: viewModel.state.progress)
                .progressViewStyle(CapsuleProgressViewStyle(tint: progressTint, height: 2))
        }
    }

    private var trailingAction: some View {
        Button {
            // Wired later
        } label: {
            trailingImage
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
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
        case .paused, .failed, .cancelled: Image(systemName: "play.fill")
        case .completed: MEGAAssets.Image.moreVerticalMediumThinOutline
        }
    }
}
