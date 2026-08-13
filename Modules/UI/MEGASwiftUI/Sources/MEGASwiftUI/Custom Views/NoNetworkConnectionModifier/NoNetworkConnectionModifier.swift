import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

extension EnvironmentValues {
    @Entry public var networkConnected: Bool = true
}

struct NoNetworkConnectionModifier<NoNetworkContent: View>: ViewModifier {
    @Environment(\.networkConnected) var networkConnected

    let showsContentWhileOffline: Bool
    @ViewBuilder let noNetworkContentViewBuilder: @MainActor () -> NoNetworkContent

    func body(content: Content) -> some View {
        if networkConnected || showsContentWhileOffline {
            content
        } else {
            noNetworkContentViewBuilder()
        }
    }
}

extension View {

    /// Replaces the view content with a custom no-network view when `networkConnected` environment value is `false`.
    /// - Parameters:
    ///   - showsContentWhileOffline: Whether the content stays on screen while offline.
    ///   - noNetworkContentViewBuilder: A closure that returns the custom view to display when there is no network connection.
    /// - Returns: A view that conditionally displays either the original content or the custom no-network view.
    public func noNetworkConnection<NoNetworkContent: View>(
        showsContentWhileOffline: Bool = false,
        @ViewBuilder noNetworkContentViewBuilder: @escaping @MainActor () -> NoNetworkContent
    ) -> some View {
        modifier(NoNetworkConnectionModifier(
            showsContentWhileOffline: showsContentWhileOffline,
            noNetworkContentViewBuilder: noNetworkContentViewBuilder
        ))
    }

    /// Replaces the view content with the default no-network view when `networkConnected` environment value is `false`.
    /// - Parameter showsContentWhileOffline: Whether the content stays on screen while offline.
    /// - Returns: A view that conditionally displays either the original content or the default no-network view.
    public func noNetworkConnection(showsContentWhileOffline: Bool = false) -> some View {
        modifier(NoNetworkConnectionModifier(showsContentWhileOffline: showsContentWhileOffline) {
            Self.makeDefaultNoNetworkContent()
        })
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
