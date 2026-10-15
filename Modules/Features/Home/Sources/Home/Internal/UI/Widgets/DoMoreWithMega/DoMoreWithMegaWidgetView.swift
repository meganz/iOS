import MEGADesignToken
import MEGAL10n
import SwiftUI

struct DoMoreWithMegaWidgetView: View {
    @State private var viewModel: DoMoreWithMegaWidgetViewModel

    init(dependency: Dependency) {
        _viewModel = State(initialValue: DoMoreWithMegaWidgetViewModel(actionHandler: dependency.actionHandler))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tilesRow
        }
        .padding(.vertical, TokenSpacing._4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.doMoreWithMega.section")
        .onAppear { viewModel.refreshTiles() }
    }

    private var header: some View {
        Text(Strings.Localizable.Home.Customization.Widget.doMoreWithMega)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, TokenSpacing._3)
            .padding(.horizontal, TokenSpacing._5)
    }

    private var tilesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: TokenSpacing._3) {
                ForEach(viewModel.tiles) { tile in
                    tileView(tile)
                }
            }
            .padding(.horizontal, TokenSpacing._5)
        }
    }

    private func tileView(_ tile: DoMoreWithMegaTile) -> some View {
        Button {
            viewModel.didTap(tile)
        } label: {
            VStack(spacing: TokenSpacing._2) {
                tile.icon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(TokenColors.Icon.inverse.swiftUI)
                    .frame(width: 56, height: 56)
                    .tileCircleBackground()
                Text(tile.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(TokenColors.Button.primary.swiftUI)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .frame(width: 100)
            .frame(minHeight: 80, alignment: .top)
            .padding(.top, TokenSpacing._3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tile.accessibilityIdentifier)
    }
}

private extension View {
    @ViewBuilder
    func tileCircleBackground() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(TokenColors.Button.primary.swiftUI.opacity(0.7)).interactive(), in: Circle())
        } else {
            background(TokenColors.Button.primary.swiftUI, in: Circle())
        }
    }
}
