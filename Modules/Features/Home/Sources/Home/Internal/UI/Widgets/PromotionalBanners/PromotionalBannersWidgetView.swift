import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

struct PromotionBannerInput: Identifiable, Sendable {
    let id: Int
    let title: String
    let actionTitle: String
    let imageURL: URL
    let backgroundURL: URL
    let link: URL?
}

struct PromotionalBannersWidgetView: View {

    @StateObject private var viewModel: PromotionalBannersWidgetViewModel
    let urlSelectionHandler: @MainActor (URL) -> Void
    let discountActionHandler: @MainActor () -> Void

    init(
        promotedPlanProvider: @escaping @Sendable () async throws -> PlanEntity?,
        urlSelectionHandler: @escaping @MainActor (URL) -> Void,
        discountActionHandler: @escaping @MainActor () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: PromotionalBannersWidgetViewModel(promotedPlanProvider: promotedPlanProvider)
        )
        self.urlSelectionHandler = urlSelectionHandler
        self.discountActionHandler = discountActionHandler
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._3) {
                Spacer()
                    .frame(width: TokenSpacing._3)
                if let content = viewModel.discountBanner {
                    DiscountBanner(
                        content: content,
                        actionHandler: discountActionHandler,
                        closeHandler: { viewModel.closeDiscountBanner() }
                    )
                }
                ForEach(viewModel.bannerViewModels) { bannerViewModel in
                    PromotionalBanner(
                        viewModel: bannerViewModel,
                        actionHandler: {
                            guard let url = bannerViewModel.input.link else { return }
                            viewModel.trackBannerTapped(url: url)
                            urlSelectionHandler(url)
                        }, closeHandler: {
                            Task {
                                await viewModel.closeBanner(bannerIdentifier: bannerViewModel.input.id)
                                guard let url = bannerViewModel.input.link else { return }
                                viewModel.trackBannerClosed(url: url)
                            }
                        }
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.bannerViewModels.count)
        .animation(.easeInOut(duration: 0.3), value: viewModel.discountBanner)
        .task {
            await viewModel.onTask()
        }
    }
}

private enum PromotionalBannerMetrics {
    static let defaultWidth = 308.0
    static let defaultHeight = 100.0
    static let closeButtonSize = 24.0
    static let bannerImageSize = 50.0
    static let discountMessageWidth = 170.0
}

private struct PromotionalBannerCardFrame: ViewModifier {
    @ScaledMetric private var bannerWidth = PromotionalBannerMetrics.defaultWidth
    @ScaledMetric private var bannerHeight = PromotionalBannerMetrics.defaultHeight

    func body(content: Content) -> some View {
        content
            .frame(width: bannerSize.width, height: bannerSize.height)
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.medium))
            .contentShape(Rectangle())
    }

    private var bannerSize: CGSize {
        let cappedWidth = min(bannerWidth, PromotionalBannerMetrics.defaultWidth * 1.5)
        let cappedHeight = min(bannerHeight, PromotionalBannerMetrics.defaultHeight * 1.5)
        return .init(width: cappedWidth, height: cappedHeight)
    }
}

private struct PromotionalBannerCloseButton: View {
    let iconColor: Color
    let closeHandler: @MainActor () -> Void

    var body: some View {
        VStack {
            Button(action: {
                closeHandler()
            }, label: {
                MEGAAssets.Image.x
                    .foregroundColor(iconColor)
                    .frame(width: PromotionalBannerMetrics.closeButtonSize, height: PromotionalBannerMetrics.closeButtonSize)
            })
            .padding(.top, TokenSpacing._3)
            .padding(.trailing, TokenSpacing._4)
            Color.clear // placeholder to expand the ZStack area vertically so that the button can be pushed to top
                .frame(width: PromotionalBannerMetrics.closeButtonSize)
        }
    }
}

private struct PromotionalBanner: View {
    @ScaledMetric private var bannerImageSize = PromotionalBannerMetrics.bannerImageSize

    @ObservedObject var viewModel: PromotionalBannerViewModel
    let actionHandler: @MainActor () -> Void
    let closeHandler: @MainActor () -> Void

    var body: some View {
        ZStack {
            backgroundImage
            HStack(spacing: 0) {
                Color.clear
                    .overlay(alignment: .topLeading) {
                        title
                    }
                    .overlay(alignment: .bottomLeading) {
                        actionButton
                    }
                bannerImage
                PromotionalBannerCloseButton(
                    iconColor: TokenColors.Icon.onColor.swiftUI,
                    closeHandler: closeHandler
                )
            }
        }
        .task {
            await viewModel.loadImages()
        }
    }

    @ViewBuilder
    private var backgroundImage: some View {
        Group {
            if let image = viewModel.backgroundImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                TokenColors.Background.surfaceInverseAccent.swiftUI
            }
        }
        .modifier(PromotionalBannerCardFrame())
    }

    private var title: some View {
        Text(viewModel.input.title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(TokenColors.Text.onColor.swiftUI)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding([.top, .leading], TokenSpacing._4)
    }

    private var actionButton: some View {
        Button(action: {
            actionHandler()
        }, label: {
            Text(viewModel.input.actionTitle)
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.onColorInverse.swiftUI)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .background(TokenColors.Button.onColor.swiftUI)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                .padding([.bottom, .leading], TokenSpacing._4)
        })
    }

    @ViewBuilder
    private var bannerImage: some View {
        Group {
            if let image = viewModel.bannerImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .frame(width: bannerImageSize, height: bannerImageSize)
        .clipped()
    }
}

private struct DiscountBanner: View {
    @ScaledMetric private var messageWidth = PromotionalBannerMetrics.discountMessageWidth

    let content: DiscountBannerContent
    let actionHandler: @MainActor () -> Void
    let closeHandler: @MainActor () -> Void

    var body: some View {
        ZStack {
            backgroundImage
            HStack(spacing: 0) {
                Color.clear
                    .overlay(alignment: .topLeading) {
                        message
                    }
                    .overlay(alignment: .bottomLeading) {
                        actionButton
                    }
                PromotionalBannerCloseButton(
                    iconColor: .black,
                    closeHandler: closeHandler
                )
            }
        }
    }

    private var backgroundImage: some View {
        MEGAAssets.Image.homeDiscountBanner
            .resizable()
            .scaledToFill()
            .modifier(PromotionalBannerCardFrame())
    }

    private var message: some View {
        Text(content.message)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundColor(Color.black) // hardcoded intead of token color as per designer decision
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: cappedMessageWidth, alignment: .leading)
            .padding([.top, .leading], TokenSpacing._4)
    }

    private var cappedMessageWidth: CGFloat {
        min(messageWidth, PromotionalBannerMetrics.discountMessageWidth * 1.5)
    }

    private var actionButton: some View {
        Button(action: {
            actionHandler()
        }, label: {
            Text(content.actionTitle)
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._3)
                .background(Color.black) // hardcoded intead of token color as per designer decision
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                .padding([.bottom, .leading], TokenSpacing._4)
        })
    }
}
