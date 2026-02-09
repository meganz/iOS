import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

extension EnvironmentValues {
    @Entry public var networkConnected: Bool = true
}

struct NoNetworkConnectionModifier: ViewModifier {
    @Environment(\.networkConnected) var networkConnected
    
    func body(content: Content) -> some View {
        if networkConnected {
            content
        } else {
            noNetworkContent
        }
    }
    
    private var noNetworkContent: some View {
        ZStack {
            TokenColors.Background.page.swiftUI
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

extension View {
    public func noNetworkConnection() -> some View {
        modifier(NoNetworkConnectionModifier())
    }
}
