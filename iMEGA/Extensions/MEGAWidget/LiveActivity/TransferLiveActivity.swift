import ActivityKit
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import Transfer
import WidgetKit

@available(iOS 16.2, *)
struct TransferLiveActivity: Widget {
    private let deepLinkURL = URL(string: "mega://widget.liveactivity.transfers")

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TransferLiveActivityAttributes.self) { context in
            TransferLiveActivityLockScreenView(
                viewState: TransferLiveActivityViewState(state: context.state, isStale: context.isStale)
            )
            .widgetURL(deepLinkURL)
        } dynamicIsland: { context in
            let viewState = TransferLiveActivityViewState(state: context.state, isStale: context.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedContent(viewState: viewState)
                }
            } compactLeading: {
                CompactLeading(viewState: viewState)
            } compactTrailing: {
                CompactTrailing(viewState: viewState)
            } minimal: {
                Minimal(viewState: viewState)
            }
            .widgetURL(deepLinkURL)
        }
    }
}

// MARK: - Expanded

@available(iOS 16.2, *)
private struct ExpandedContent: View {
    let viewState: TransferLiveActivityViewState

    var body: some View {
        VStack(spacing: TokenSpacing._3) {
            HStack {
                IconBadge(icon: viewState.statusIcon, tint: viewState.statusIconTint)
                Text(viewState.statusText)
                    .font(.liveActivityStatus)
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text(viewState.percentageText)
                    .font(.liveActivityPercentageLg)
                    .tracking(-0.4)
                    .foregroundStyle(viewState.tintColor)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, TokenSpacing._7)

            ProgressView(value: viewState.progressFraction)
                .progressViewStyle(CapsuleProgressViewStyle(tint: viewState.tintColor, height: 8))
                .padding(.horizontal, TokenSpacing._7)

            HStack {
                Text(viewState.fileCountText)
                    .font(.liveActivityCaption)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .contentTransition(.numericText())
                Spacer()
                Text(viewState.speed)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .contentTransition(.identity)
            }
            .padding(.horizontal, TokenSpacing._9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewState.accessibilityDescription)
    }
}

// MARK: - Compact / Minimal

@available(iOS 16.2, *)
private struct CompactLeading: View {
    let viewState: TransferLiveActivityViewState

    var body: some View {
        viewState.statusIcon
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(viewState.statusIconTint)
            .accessibilityHidden(true)
    }
}

@available(iOS 16.2, *)
private struct CompactTrailing: View {
    let viewState: TransferLiveActivityViewState

    var body: some View {
        Text(viewState.percentageText)
            .font(.liveActivityPercentageSm)
            .tracking(-0.4)
            .foregroundStyle(viewState.tintColor)
            .contentTransition(.numericText())
            .accessibilityLabel(viewState.compactAccessibilityDescription)
    }
}

@available(iOS 16.2, *)
private struct Minimal: View {
    let viewState: TransferLiveActivityViewState

    var body: some View {
        ZStack {
            CircularProgressView(progress: viewState.progressFraction, tint: viewState.tintColor)
            viewState.statusIcon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(viewState.statusIconTint)
        }
        .frame(width: 27, height: 27)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewState.compactAccessibilityDescription)
    }
}

// MARK: - Helpers

@available(iOS 16.2, *)
private struct IconBadge: View {
    let icon: Image
    let tint: Color

    var body: some View {
        icon
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(Circle().fill(TokenColors.Background.surface2.swiftUI))
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
