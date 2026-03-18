import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

extension EnvironmentValues {
    @Entry public var networkConnected: Bool = true
}

struct NoNetworkConnectionModifier<NoNetworkContent: View>: ViewModifier {
    @Environment(\.networkConnected) var networkConnected

    @ViewBuilder let noNetworkContentViewBuilder: @MainActor () -> NoNetworkContent

    func body(content: Content) -> some View {
        if networkConnected {
            content
        } else {
            noNetworkContentViewBuilder()
        }
    }
}

extension View {

    /// Replaces the view content with a custom no-network view when `networkConnected` environment value is `false`.
    /// - Parameter noNetworkContentViewBuilder: A closure that returns the custom view to display when there is no network connection.
    /// - Returns: A view that conditionally displays either the original content or the custom no-network view.
    public func noNetworkConnection<NoNetworkContent: View>(@ViewBuilder noNetworkContentViewBuilder: @escaping @MainActor () -> NoNetworkContent) -> some View {
        modifier(NoNetworkConnectionModifier(noNetworkContentViewBuilder: noNetworkContentViewBuilder))
    }

    /// Replaces the view content with the default no-network view when `networkConnected` environment value is `false`.
    /// - Returns: A view that conditionally displays either the original content or the default no-network view.
    public func noNetworkConnection() -> some View {
        modifier(NoNetworkConnectionModifier { Self.makeDefaultNoNetworkContent() })
    }

    @MainActor
    private static func makeDefaultNoNetworkContent() -> some View {
        ZStack {
            TokenColors.Background.page.swiftUI
                .ignoresSafeArea(edges: [.bottom])
            VStack {
                MEGAAssets.Image.glassNoCloud
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                Text(Strings.Localizable.noInternetConnection)
                    .font(.headline.weight(.regular))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            .padding(.bottom, 70)
        }
    }
}
