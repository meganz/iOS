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
    struct Dependency {
        let bannerUseCase: any UserBannerUseCaseProtocol
    }

    @StateObject private var viewModel: PromotionalBannersWidgetViewModel
    let urlSelectionHandler: @MainActor (URL) -> Void

    init(
        dependency: Dependency,
        urlSelectionHandler: @escaping @MainActor (URL) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PromotionalBannersWidgetViewModel(bannerUseCase: dependency.bannerUseCase))
        self.urlSelectionHandler = urlSelectionHandler
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._3) {
                Spacer()
                    .frame(width: TokenSpacing._3)
                ForEach(viewModel.bannerInputs) { input in
                    PromotionalBanner(
                        input: input,
                        actionHandler: {
                            guard let url = input.link else { return }
                            urlSelectionHandler(url)
                        }, closeHandler: {
                            Task {
                                await viewModel.closeBanner(bannerIdentifier: input.id)
                            }
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.bannerInputs.count)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.bannerInputs.count)
        .task {
            await viewModel.onTask()
        }
    }
}

private struct PromotionalBanner: View {
    enum Constants {
        static let defaultWidth = 308.0
        static let defaultHeight = 100.0
        static let closeButtonSize = 24.0
        static let bannerImageSize = 50.0
    }

    @ScaledMetric private var bannerWidth = Constants.defaultWidth
    @ScaledMetric private var bannerHeight = Constants.defaultHeight
    @ScaledMetric private var bannerImageSize = Constants.bannerImageSize

    let input: PromotionBannerInput
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
                closeButton
            }
        }
    }

    private var bannerSize: CGSize {
        let cappedWidth = min(bannerWidth, Constants.defaultWidth * 1.5)
        let cappedHeight = min(bannerHeight, Constants.defaultHeight * 1.5)
        return .init(width: cappedWidth, height: cappedHeight)
    }

    private var backgroundImage: some View {
        AsyncImage(url: input.backgroundURL) { result in
            Group {
                if let image = result.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    TokenColors.Background.inverse.swiftUI
                }

            }
            .frame(width: bannerSize.width, height: bannerSize.height)
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.medium))
            .contentShape(Rectangle())
        }
    }

    private var title: some View {
        Text(input.title)
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
            Text(input.actionTitle)
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

    private var bannerImage: some View {
        AsyncImage(url: input.imageURL) { result in
            Group {
                if let image = result.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    TokenColors.Background.inverse.swiftUI
                }

            }
            .frame(width: bannerImageSize, height: bannerImageSize)
            .clipped()
        }
    }

    private var closeButton: some View {
        VStack {
            Button(action: {
                closeHandler()
            }, label: {
                MEGAAssets.Image.x
                    .foregroundColor(TokenColors.Icon.onColor.swiftUI)
                    .frame(width: Constants.closeButtonSize, height: Constants.closeButtonSize)
            })
            .padding(.top, TokenSpacing._3)
            .padding(.trailing, TokenSpacing._4)
            Color.clear // placeholder to expand the ZStack area vertically so that the button can be pushed to top
                .frame(width: Constants.closeButtonSize)
        }
    }
}
