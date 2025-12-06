import MEGADesignToken
import SwiftUI

public struct RevampedContentUnavailableView: View {

    let viewModel: ContentUnavailableViewModel

    public init(
        viewModel: ContentUnavailableViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geo in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    image(inGeometryProxy: geo)
                    Spacer()
                        .frame(height: TokenSpacing._3)
                    title
                    Spacer()
                        .frame(height: TokenSpacing._5)
                    subtitle
                    Spacer()
                        .frame(height: TokenSpacing._5)
                    actionsView
                    Spacer()
                }
                .frame(maxWidth: 380)
                .padding(.horizontal, TokenSpacing._7)
                Spacer()
            }
        }
    }

    private func image(inGeometryProxy geo: GeometryProxy) -> some View {
        viewModel.image
            .resizable()
            .scaledToFit()
            .frame(
                width: iconSize(geo),
                height: iconSize(geo)
            )
    }

    private var title: some View {
        Text(viewModel.title)
            .font(.title3)
            .multilineTextAlignment(.center)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }

    @ViewBuilder
    private var subtitle: some View {
        if let subtitle = viewModel.subtitle {
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .multilineTextAlignment(.center)
        } else {
            EmptyView()
        }
    }

    private func iconSize(_ proxy: GeometryProxy) -> CGFloat {
        // [SAO-3140] Need to adjust icon size for iPad
        proxy.size.height > 300 ? 120 : 80
    }

    @ViewBuilder
    private var actionsView: some View {
        VStack {
            ForEach(viewModel.buttonActions, id: \.id) { action in
                actionButton(action: action)
            }
        }
        .frame(maxWidth: 480)
    }

    private func actionButton(action: ContentUnavailableViewModel.ButtonAction) -> some View {
        Button(action: action.handler, label: {
            if let image = action.image {
                Label {
                    buttonText(for: action.title)
                } icon: {
                    image
                        .foregroundStyle(TokenColors.Icon.inverseAccent.swiftUI)
                }
            } else {
                buttonText(for: action.title)
            }
        })
        .frame(height: 52)
        .padding(.horizontal, TokenSpacing._8)
        .background(TokenColors.Button.primary.swiftUI)
        .cornerRadius(TokenRadius.medium)
    }

    private func buttonText(for title: String) -> some View {
        Text(title)
            .fontWeight(.semibold)
            .foregroundStyle(TokenColors.Text.inverseAccent.swiftUI)
    }
}

private extension ContentUnavailableViewModel {
    // For revamped UI we only display Button actions, no menu actions
    var buttonActions: [ContentUnavailableViewModel.ButtonAction] {
        actions.compactMap({ $0 as? ContentUnavailableViewModel.ButtonAction })
    }
}
