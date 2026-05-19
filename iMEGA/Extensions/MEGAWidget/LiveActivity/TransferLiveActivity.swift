import ActivityKit
import MEGAAssetsBundle
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import Transfer
import WidgetKit

@available(iOS 16.2, *)
struct TransferLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TransferLiveActivityAttributes.self) { context in
            TransferLiveActivityLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    expandedContent(state: context.state)
                }
            } compactLeading: {
                context.state.statusIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(context.state.statusIconTint)
            } compactTrailing: {
                Text(context.state.percentageText)
                    .font(.liveActivityPercentageSm)
                    .tracking(-0.4)
                    .foregroundStyle(context.state.tintColor)
                    .contentTransition(.numericText())
            } minimal: {
                compactProgressIcon(state: context.state)
            }
        }
    }

    // MARK: - Expanded Dynamic Island

    private func expandedContent(state: TransferLiveActivityAttributes.ContentState) -> some View {
        VStack(spacing: TokenSpacing._3) {
            HStack {
                iconBadge(state.statusIcon, tint: state.statusIconTint)
                Text(state.statusText)
                    .font(.liveActivityStatus)
                    .tracking(-0.4)
                    .lineLimit(1)
                Spacer()
                Text(state.percentageText)
                    .font(.liveActivityPercentageLg)
                    .tracking(-0.4)
                    .foregroundStyle(state.tintColor)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, TokenSpacing._7)

            ProgressView(value: state.progressFraction)
                .progressViewStyle(CapsuleProgressViewStyle(tint: state.tintColor, height: 8))
                .padding(.horizontal, TokenSpacing._7)

            HStack {
                Text(state.fileCountText)
                    .font(.liveActivityCaption)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .contentTransition(.numericText())
                Spacer()
                Text(state.formattedSpeed)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .contentTransition(.identity)
            }
            .padding(.horizontal, TokenSpacing._9)
        }
    }

    // MARK: - Compact / Minimal

    private func compactProgressIcon(state: TransferLiveActivityAttributes.ContentState) -> some View {
        ZStack {
            CircularProgressView(
                progress: state.progressFraction,
                tint: state.tintColor
            )
            state.statusIcon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(state.statusIconTint)
        }
        .frame(width: 27, height: 27)
    }

    // MARK: - Helpers

    private func iconBadge(_ icon: Image, tint: Color) -> some View {
        icon
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(Circle().fill(TokenColors.Background.surface2.swiftUI))
    }
}

// MARK: - Status Icon

@available(iOS 16.2, *)
extension TransferLiveActivityAttributes.ContentState {

    var statusIcon: Image {
        switch state {
        case .paused: MEGAImageBundle.pauseSmallRegularSolid
        case .error: MEGAImageBundle.alertCircleSmallRegularSolid
        case .overquota: MEGAImageBundle.alertTriangleSmallRegularSolid
        case .completed: MEGAImageBundle.checkSmallRegularOutline
        case .active:
            switch direction {
            case .mixed: MEGAImageBundle.arrowUpDownSmallRegularOutline
            case .downloading: MEGAImageBundle.arrowDownSmallReguarOutline
            case .uploading, .none: MEGAImageBundle.arrowUpSmallReguarOutline
            }
        }
    }

    var tintColor: Color {
        switch state {
        case .active, .completed: TokenColors.Support.success.swiftUI
        case .paused: TokenColors.Icon.secondary.swiftUI
        case .error: TokenColors.Support.error.swiftUI
        case .overquota: TokenColors.Support.warning.swiftUI
        }
    }

    var statusIconTint: Color {
        switch state {
        case .error:
            TokenColors.Support.error.swiftUI
        case .overquota:
            TokenColors.Support.warning.swiftUI
        case .completed, .active, .paused:
            TokenColors.Icon.primary.swiftUI
        }
    }
}

// MARK: - Typography

extension Font {
    static let liveActivityCompactCount = Font.system(size: 15, weight: .semibold).monospacedDigit()
    static let liveActivityStatus = Font.system(size: 14, weight: .semibold)
    static let liveActivityPercentageLg = Font.system(size: 32, weight: .semibold).monospacedDigit()
    static let liveActivityPercentageSm = Font.system(size: 14, weight: .semibold).monospacedDigit()
    static let liveActivityCaption = Font.system(size: 12, weight: .regular)
    static let liveActivityCaptionMd = Font.system(size: 12, weight: .medium)
}
