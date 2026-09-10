import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct MenuDiscountBannerView: View {
    @ScaledMetric private var height = MenuDiscountBannerMetrics.height
    @ScaledMetric private var messageWidth = MenuDiscountBannerMetrics.messageWidth

    let content: MenuDiscountBannerContent
    let actionHandler: @MainActor () -> Void
    let closeHandler: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            message
            Spacer(minLength: TokenSpacing._2)
            bottomRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TokenSpacing._3)
        .padding(.vertical, TokenSpacing._4)
        .frame(height: cappedHeight)
        .background { backgroundImage }
        .clipShape(RoundedRectangle(cornerRadius: TokenRadius.medium))
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) { closeButton }
        .padding(.horizontal, TokenSpacing._4)
        .padding(.vertical, TokenSpacing._3)
    }

    private var bottomRow: some View {
        HStack(alignment: .bottom, spacing: TokenSpacing._3) {
            countdown
            Spacer(minLength: 0)
            actionButton
                .layoutPriority(1)
        }
    }

    private var cappedHeight: CGFloat {
        min(height, MenuDiscountBannerMetrics.height * 1.5)
    }

    private var backgroundImage: some View {
        MEGAAssets.Image.homeDiscountBanner
            .resizable()
            .scaledToFill()
    }

    private var message: some View {
        Text(content.message)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(MenuDiscountBannerMetrics.primaryText)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: cappedMessageWidth, alignment: .leading)
    }

    private var cappedMessageWidth: CGFloat {
        min(messageWidth, MenuDiscountBannerMetrics.messageWidth * 1.5)
    }

    @ViewBuilder
    private var countdown: some View {
        if let deadline = content.deadline {
            MenuDiscountBannerCountdownView(deadline: deadline)
        }
    }

    private var closeButton: some View {
        Button(action: closeHandler) {
            MEGAAssets.Image.x
                .foregroundColor(MenuDiscountBannerMetrics.primaryText)
                .frame(
                    width: MenuDiscountBannerMetrics.closeButtonSize,
                    height: MenuDiscountBannerMetrics.closeButtonSize
                )
        }
        .padding(.top, TokenSpacing._2)
        .padding(.trailing, TokenSpacing._3)
    }

    private var actionButton: some View {
        Button(action: actionHandler) {
            Text(content.actionTitle)
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .background(MenuDiscountBannerMetrics.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
        }
    }
}

private struct MenuDiscountBannerCountdownView: View {
    let deadline: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let countdown = SubscriptionCountdown.remaining(until: deadline, from: context.date)

            HStack(spacing: TokenSpacing._3) {
                unit(value: countdown.days, label: Strings.Localizable.SubscriptionPurchase.Revamp.Countdown.days(countdown.days))
                unit(value: countdown.hours, label: Strings.Localizable.SubscriptionPurchase.Revamp.Countdown.hours(countdown.hours))
                unit(value: countdown.minutes, label: Strings.Localizable.SubscriptionPurchase.Revamp.Countdown.minutes(countdown.minutes))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    private func unit(value: Int, label: String) -> some View {
        HStack(spacing: TokenSpacing._1) {
            Text(String(format: "%02d", value))
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(MenuDiscountBannerMetrics.primaryText)

            Text(label)
                .font(.footnote)
                .foregroundColor(MenuDiscountBannerMetrics.secondaryText)
        }
    }
}

private enum MenuDiscountBannerMetrics {
    static let height = 112.0
    static let messageWidth = 212.0
    static let closeButtonSize = 24.0

    static let primaryText = Color.black
    static let secondaryText = Color.black.opacity(0.6)
}
